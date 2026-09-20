{ pkgs, ... }: {
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

  networking.bridges.br-lab.interfaces = [ ];
  networking.interfaces.br-lab.ipv4.addresses = [ { address = "10.0.10.1"; prefixLength = 24; } ];
  networking.nat = { enable = true; internalInterfaces = [ "br-lab" ]; };

  containers.lab-sensor = {
    autoStart = false;
    privateNetwork = true;
    hostBridge = "br-lab";
    localAddress = "10.0.10.2/24";

    config = { config, pkgs, ... }: {

      networking.defaultGateway = "10.0.10.1";
      networking.nameservers = [
        "8.8.8.8"
        "1.1.1.1"
      ];

      # --- 1. Suricata: Motor IDS/IPS ---
      services.suricata = {
        enable = true;
        settings = {
          default-rule-path = "/var/lib/suricata-rules/rules";
          rule-files = [ "*.rules" ];
          classification-file = "/var/lib/suricata-rules/rules/classification.config";

          # --- Habilitar la escritura de logs ---
          outputs = [
            {
              fast = {
                enabled = true;
                filename = "/var/log/suricata/fast.log"; # <--- RUTA ABSOLUTA
                append = true;
              };
            }
            {
              eve-log = {
                enabled = true;
                filetype = "regular";
                filename = "/var/log/suricata/eve.json"; # <--- RUTA ABSOLUTA
                types = [
                  "alert"
                  "http"
                  "dns"
                  "tls"
                ];
              };
            }
          ];

          af-packet = [
            {
              interface = "eth0";
              cluster-id = 99;
              cluster-type = "cluster_flow";
              defrag = "yes";
            }
          ];
        };
      };

      # --- 2. Suricata: Actualización Declarativa ---
      systemd.services.suricata = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [
          curl
          gnutar
          gzip
        ];

        serviceConfig = {
          ReadWritePaths = [
            "/var/lib/suricata-rules"
            "/var/log/suricata"
          ];
        };

        preStart = pkgs.lib.mkBefore ''
          mkdir -p /var/lib/suricata-rules
          mkdir -p /var/log/suricata


          curl -sL https://rules.emergingthreats.net/open/suricata-7.0/emerging.rules.tar.gz | tar -xzf - -C /var/lib/suricata-rules/
        '';
      };

      # --- 3. Zeek: Análisis de Red (Corregido) ---
      systemd.services.zeek = {
        description = "Zeek Network Security Monitor";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          # Le decimos a systemd que cree y gestione automáticamente /var/lib/zeek
          StateDirectory = "zeek";
          WorkingDirectory = "/var/lib/zeek";

          ExecStart = "${pkgs.zeek}/bin/zeek -i eth0 local";
          Restart = "always";
        };
      };

      # --- 4. Paquetes y Sistema ---
      environment.systemPackages = with pkgs; [
        zeek
        tcpdump
        termshark
        htop
        # Curl y Tar eliminados del entorno global; solo viven en el scope de Suricata.
      ];

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
      };

      system.stateVersion = "25.11";
    };
  };
}
