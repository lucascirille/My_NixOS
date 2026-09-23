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

  # Creates a security wrapper for 'ubridge'. Ubridge is used to bridge virtual 
  # network nodes (often used in GNS3 or lab topologies). The wrapper grants it 
  # administrative network capabilities (cap_net_admin, cap_net_raw=ep) so it 
  # can manipulate network interfaces while running safely under its own group.
  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin,cap_net_raw=ep";
    owner = "root";
    group = "ubridge";
    permissions = "u+rx,g+rx,o+rx";
  };
  users.groups.ubridge = { };

  # ===========================================================================
  # 3. LAB NETWORK BRIDGE (br-lab)
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
  # 'br-lab' (the internal interface) can route out to the internet through 
  # the host machine's primary connection.
  networking.nat = { 
    enable = true; 
    internalInterfaces = [ "br-lab" ]; 
  };

  # ===========================================================================
  # 4. WEBRTC / VESKTOP CONFLICT RESOLUTION
  # ===========================================================================
  # WebRTC (used by Vesktop/Discord) attempts to bind to all active interfaces.
  # Because br-lab has a static IP, the network manager forces it UP by default, 
  # trapping outgoing media packets. This systemd service waits for the network 
  # stack to finish initializing, then immediately forces the bridge DOWN.
  systemd.services.down-br-lab = {
    description = "Force br-lab interface down to prevent WebRTC routing conflicts";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig.Type = "oneshot";
    # Uses the absolute path to iproute2 to guarantee execution during boot
    script = "${pkgs.iproute2}/bin/ip link set br-lab down || true";
  };

  # ===========================================================================
  # 5. SECURITY LAB CONTAINER (lab-sensor)
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

      # --- 5A. Suricata: IDS/IPS Engine ---
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

      # --- 5B. Suricata: Declarative Rules Update ---
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

      # --- 5C. Zeek: Network Security Monitor ---
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

      # --- 5D. Packages and System Configuration ---
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
