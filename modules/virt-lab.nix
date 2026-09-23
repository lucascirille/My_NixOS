{ pkgs, ... }: {
  # ===========================================================================
  # 1. VIRTUALIZATION & HYPERVISOR
  # ===========================================================================
  # Enables the libvirtd daemon to manage virtual machines and containers.
  # Configures QEMU/KVM as the backend hypervisor, running as root to ensure 
  # full hardware access, and enables Software TPM (swtpm) for VM security.
  virtualisation.libvirtd = {
    enable = true;
    qemu = { 
      package = pkgs.qemu_kvm; 
      runAsRoot = true; 
      swtpm.enable = true; 
    };
  };

  # ===========================================================================
  # 2. PACKET ANALYSIS & NETWORKING TOOLS
  # ===========================================================================
  # Installs Wireshark globally and configures the necessary system permissions
  # (like adding users to the 'wireshark' group) to capture packets without root.
  programs.wireshark = { 
    enable = true; 
    package = pkgs.wireshark; 
  };

  # Creates a security wrapper for 'ubridge' (used to bridge virtual network nodes). 
  # The wrapper grants it administrative network capabilities (cap_net_admin, 
  # cap_net_raw=ep) so it can manipulate interfaces safely under its own group.
  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin,cap_net_raw=ep";
    owner = "root";
    group = "ubridge";
    permissions = "u+rx,g+rx,o+rx";
  };
  users.groups.ubridge = { };

  # ===========================================================================
  # 3. LAB NETWORK BRIDGE (br-lab) & LIFECYCLE MANAGEMENT
  # ===========================================================================
  # Defines a virtual network bridge named 'br-lab' with no physical interfaces 
  # attached initially. It acts as an isolated virtual switch for the lab.
  networking.bridges.br-lab.interfaces = [ ];
  
  # Assigns the static IPv4 address 10.0.10.1 to the bridge, which will act as 
  # the default gateway for any containers or VMs connected to it.
  networking.interfaces.br-lab.ipv4.addresses = [ 
    { address = "10.0.10.1"; prefixLength = 24; } 
  ];
  
  # Enables Network Address Translation (NAT) so that traffic originating from 
  # 'br-lab' (the internal interface) can route out to the internet.
  networking.nat = { 
    enable = true; 
    internalInterfaces = [ "br-lab" ]; 
  };

  # --- 3A. Prevent NetworkManager Interference ---
  # Tells NetworkManager to completely ignore the br-lab interface so it doesn't
  # automatically force it UP when it detects the static IP address.
  networking.networkmanager.unmanaged = [ "br-lab" ];

  # --- 3B. Force Bridge DOWN on Creation ---
  # Injects a command to bring the bridge down the exact millisecond NixOS 
  # finishes assigning the 10.0.10.1 IP address during early boot.
  systemd.services."network-addresses-br-lab".postStart = ''
    ${pkgs.iproute2}/bin/ip link set br-lab down || true
  '';

  # --- 3C. Tie Bridge State to Container Power Cycle ---
  # A standalone lifecycle service. It waits for the container to start, brings
  # the bridge UP, and when the container stops, it brings the bridge DOWN.
  systemd.services.br-lab-lifecycle = {
    description = "Manage br-lab interface state alongside lab-sensor container";
    
    # Tie this service directly to the container's power state
    bindsTo = [ "container@lab-sensor.service" ];
    partOf = [ "container@lab-sensor.service" ];
    wantedBy = [ "container@lab-sensor.service" ];
    
    # Ensure the bridge is UP before the container attempts to start
    before = [ "container@lab-sensor.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true; # Required so it knows when to trigger the Stop command
      ExecStart = "${pkgs.iproute2}/bin/ip link set br-lab up";
      ExecStop = "${pkgs.iproute2}/bin/ip link set br-lab down";
    };
  };

  # ===========================================================================
  # 4. SECURITY LAB CONTAINER (lab-sensor)
  # ===========================================================================
  # Defines a declarative systemd-nspawn container acting as a network sensor.
  # It connects to the host via the 'br-lab' bridge and is assigned 10.0.10.2.
  containers.lab-sensor = {
    autoStart = false; # Kept off by default to save resources
    privateNetwork = true;
    hostBridge = "br-lab";
    localAddress = "10.0.10.2/24";

    # The internal configuration of the container
    config = { config, pkgs, ... }: {
      
      # Container networking setup
      networking.defaultGateway = "10.0.10.1";
      networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

      # --- 4A. Suricata: IDS/IPS Engine ---
      # Intrusion Detection System configuration. It analyzes traffic in real-time.
      services.suricata = {
        enable = true;
        settings = {
          default-rule-path = "/var/lib/suricata-rules/rules";
          rule-files = [ "*.rules" ];
          classification-file = "/var/lib/suricata-rules/rules/classification.config";

          # Configures log outputs: 'fast.log' for quick alerts and 'eve.json' 
          # for structured, parseable telemetry (DNS, HTTP, TLS, Alerts).
          outputs = [
            { fast = { enabled = true; filename = "/var/log/suricata/fast.log"; append = true; }; }
            { eve-log = { enabled = true; filetype = "regular"; filename = "/var/log/suricata/eve.json"; types = [ "alert" "http" "dns" "tls" ]; }; }
          ];

          # Configures Suricata to listen on 'eth0' (the container's veth link to br-lab)
          # using af-packet for high-performance packet capture.
          af-packet = [
            { interface = "eth0"; cluster-id = 99; cluster-type = "cluster_flow"; defrag = "yes"; }
          ];
        };
      };

      # --- 4B. Suricata: Declarative Rules Update ---
      # A preStart hook that automatically downloads and extracts the latest 
      # Emerging Threats (ET) open ruleset before the Suricata service starts.
      systemd.services.suricata = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [ curl gnutar gzip ];

        serviceConfig = {
          ReadWritePaths = [ "/var/lib/suricata-rules" "/var/log/suricata" ];
        };

        preStart = pkgs.lib.mkBefore ''
          mkdir -p /var/lib/suricata-rules
          mkdir -p /var/log/suricata
          curl -sL https://rules.emergingthreats.net/open/suricata-7.0/emerging.rules.tar.gz | tar -xzf - -C /var/lib/suricata-rules/
        '';
      };

      # --- 4C. Zeek: Network Security Monitor ---
      # Defines a custom systemd service for Zeek. Unlike Suricata (which alerts), 
      # Zeek logs protocol metadata and connections for forensic analysis.
      systemd.services.zeek = {
        description = "Zeek Network Security Monitor";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          StateDirectory = "zeek"; # Let systemd securely manage /var/lib/zeek 
          WorkingDirectory = "/var/lib/zeek";
          ExecStart = "${pkgs.zeek}/bin/zeek -i eth0 local";
          Restart = "always";
        };
      };

      # --- 4D. Packages and System Configuration ---
      # Installs localized diagnostic tools strictly inside the container namespace.
      environment.systemPackages = with pkgs; [
        zeek
        tcpdump
        termshark
        htop
      ];

      # Enables IP forwarding inside the container's kernel namespace, allowing 
      # it to route packets if used as an inline IPS (Intrusion Prevention System).
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
      };

      system.stateVersion = "25.11";
    };
  };
}
