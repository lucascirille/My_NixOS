{ pkgs, ... }: {
  # ==============================================================================
  # 1. Virtualización y Herramientas de Red
  # ==============================================================================
  virtualisation.libvirtd = {
    enable = true;
    qemu = { package = pkgs.qemu_kvm; runAsRoot = true; swtpm.enable = true; };
  };

  programs.wireshark = { enable = true; package = pkgs.wireshark; };

  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin,cap_net_raw=ep";
    owner = "root";
    group = "ubridge";
    permissions = "u+rx,g+rx,o+rx";
  };
  users.groups.ubridge = { };

  # ==============================================================================
  # 2. Gestión Moderna de Redes (systemd-networkd)
  # ==============================================================================
  systemd.network.enable = true;

  # Crea el dispositivo de red virtual (el "cable" o switch virtual)
  systemd.network.netdevs."10-br-lab" = {
    netdevConfig = {
      Kind = "bridge";
      Name = "br-lab";
    };
  };

  # Asigna la IP y define la política de encendido del bridge
  systemd.network.networks."10-br-lab" = {
    matchConfig.Name = "br-lab";
    linkConfig.ActivationPolicy = "manual"; # ← CLAVE: Mantiene el bridge DOWN por defecto
    address = [ "10.0.10.1/24" ];
  };

  # ==============================================================================
  # 3. Enrutamiento y NAT
  # ==============================================================================
  networking.nat = { 
    enable = true; 
    internalInterfaces = [ "br-lab" ]; 
  };

  # ==============================================================================
  # 4. Definición del Contenedor NixOS
  # ==============================================================================
  containers.lab-sensor = {
    autoStart = false;        # No arranca al iniciar el host
    privateNetwork = true;    # Aísla la red del contenedor
    hostBridge = "br-lab";    # Conecta la interfaz del contenedor a este bridge
    localAddress = "10.0.10.2/24"; # IP del contenedor dentro del bridge

    config = { config, pkgs, ... }: {
      networking.defaultGateway = "10.0.10.1";
      networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

      # --- 4.1. Suricata: Motor IDS/IPS ---
      services.suricata = {
        enable = true;
        settings = {
          default-rule-path = "/var/lib/suricata-rules/rules";
          rule-files = [ "*.rules" ];
          classification-file = "/var/lib/suricata-rules/rules/classification.config";
          outputs = [
            { fast = { enabled = true; filename = "/var/log/suricata/fast.log"; append = true; }; }
            { eve-log = { enabled = true; filetype = "regular"; filename = "/var/log/suricata/eve.json"; types = [ "alert" "http" "dns" "tls" ]; }; }
          ];
          af-packet = [ { interface = "eth0"; cluster-id = 99; cluster-type = "cluster_flow"; defrag = "yes"; } ];
        };
      };

      # --- 4.2. Suricata: Descarga de Reglas antes de iniciar ---
      systemd.services.suricata = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [ curl gnutar gzip ];
        serviceConfig = { ReadWritePaths = [ "/var/lib/suricata-rules" "/var/log/suricata" ]; };
        preStart = pkgs.lib.mkBefore ''
          mkdir -p /var/lib/suricata-rules
          mkdir -p /var/log/suricata
          curl -sL https://rules.emergingthreats.net/open/suricata-7.0/emerging.rules.tar.gz | tar -xzf - -C /var/lib/suricata-rules/
        '';
      };

      # --- 4.3. Zeek: Análisis de Red ---
      systemd.services.zeek = {
        description = "Zeek Network Security Monitor";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          StateDirectory = "zeek";
          WorkingDirectory = "/var/lib/zeek";
          ExecStart = "${pkgs.zeek}/bin/zeek -i eth0 local";
          Restart = "always";
        };
      };

      # --- 4.4. Paquetes y Parámetros del Kernel ---
      environment.systemPackages = with pkgs; [ zeek tcpdump termshark htop ];
      boot.kernel.sysctl = { "net.ipv4.ip_forward" = 1; };
      system.stateVersion = "25.11";
    };
  };

  # ==============================================================================
  # 5. CORRECCIÓN: Levantar el bridge justo antes de arrancar el contenedor
  # ==============================================================================
  systemd.services."container@lab-sensor".preStart = ''
    ip link set br-lab up
  '';
}
