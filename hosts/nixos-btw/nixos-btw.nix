{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Bootloader & Quiet Boot
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false; # Must be disabled when using lanzaboote
      efi.canTouchEfiVariables = true;
    };

    kernel = {
      sysctl = {
        "vm.max_map_count" = 262144;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    kernelParams = [
      "quiet"
      "loglevel=4"
      "systemd.show_status=true"
    ];
    consoleLogLevel = 4;
  };

  security.tpm2.enable = true;
  # Deshabilitamos libvirtd cuando se esta usando una maquina virtual ya que da error por validacion de tpm
  systemd.services.libvirtd.unitConfig.ConditionVirtualization = "!vm";


  # DNS Resolution & MpowerManagement
  networking.nameservers = [];


  stylix = {
    enable = true;
    image = ../../home/assets/Wallpapers/current.jpg;
    polarity = "dark";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

  };



  # Secret manager using ssh host key
  sops = {
    defaultSopsFile = ../../secrets/hosts/nixos-btw.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # Define the secret for the neo user password
    secrets."neo_password" = {
      neededForUsers = true;
    };
  };

  # Prevent manual password modifications (requires sops to manage it)
  users.mutableUsers = false;

  nixpkgs.config.allowUnfree = true;

  # Hostname & Universal Hardware Support
  networking.hostName = "nixos-btw";
  networking.networkmanager.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Specialisations (Boot choices in GRUB)
  specialisation = {
    vm.configuration = {
    imports = [ ../../specialisations/vm.nix ];
    };
    # gaming.configuration = {
    # imports = [ ../../specialisations/gaming.nix ];
    #   };
  };

  # Display Manager (Ly) & Window Manager (Qtile)
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    updateDbusEnvironment = true;
    windowManager.qtile = {
      enable = true;
      extraPackages =
        python3Packages: with python3Packages; [
          qtile-extras
        ];
    };
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      brightness_down_key = "F5";
      brightness_up_key = "F6";
      brightness_down_cmd = "${pkgs.brightnessctl}/bin/brightnessctl set 20%-";
      brightness_up_cmd = "${pkgs.brightnessctl}/bin/brightnessctl set 20%+";
    };
  };

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false; # Recommended for security
    };
  };

  services.blueman.enable = true;

  # --- Native Application Sandboxing ---

  services.flatpak = {
    enable = true;

    # Declaramos los repositorios que queremos usar
    remotes = lib.mkOptionDefault [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # Declaramos exactamente qué aplicaciones instalar
    packages = [
      "com.github.tchx84.Flatseal"
    ];

    # Limpieza automática de apps que quites de la lista
    uninstallUnmanaged = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true; # Directs all xdg-open calls to the portal handler
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # Enable GNOME Keyring daemon
  services.gnome.gnome-keyring.enable = false;

  # Automatically unlock the keyring when loggin in through Ly
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow ubridge to set network permissions (packet capture / tap devices)
  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin,cap_net_raw=ep";
    owner = "root";
    group = "ubridge";
    permissions = "u+rx,g+rx,o+rx";
  };

  # Create the ubridge group
  users.groups.ubridge = { };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General.AutoEnable = "false";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-compute-runtime # Driver OpenCL para gráficas Intel
      pocl # Soporte OpenCL genérico para CPUs
      rocmPackages.clr.icd # Driver HIP/OpenCL para gráficas AMD Radeon
    ];
  };

  systemd.services.bluetooth.wantedBy = lib.mkForce [ ];

  programs.obs-studio = {
    enable = true;

    # Habilita la cámara virtual (opcional pero muy útil)
    enableVirtualCamera = true;

    # Añade plugins oficiales de manera declarativa
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };

  # System User & Shell
  programs.zsh.enable = true;

  # Enables Wireshark with setcap privileges for dumping packets as a non-root user
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # Provides the Wireshark GUI
  };

  # Enable Steam with hardware & network integration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Fast LAN game downloads
    extraCompatPackages = with pkgs; [
    proton-ge-bin
  ];
  };

  system.userActivationScripts.steamDevCfg.text = ''
  mkdir -p "$HOME/.local/share/Steam"
  echo "unShaderBackgroundProcessingThreads $(nproc)" > "$HOME/.local/share/Steam/steam_dev.cfg"
'';

  # Gaming performance booster
  programs.gamemode.enable = true;

  users.users.neo = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "render"
      "libvirtd"
      "wireshark"
      "ubridge"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree ];
    # Point to the hashed password inside sops
    hashedPasswordFile = config.sops.secrets."neo_password".path;
  };

  # Required system daemon and KVM/QEMU setup
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  virtualisation.docker = {
    enable = true;
    # Prune unused images and containers periodically
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    # Enable rootless mode if preferred for security
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  services.dbus.enable = true;

  # Desktop Integration & Thunar File Manager
  programs.dconf.enable = true;
  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;

  programs.thunar = {
    enable = true;
    plugins = [
      pkgs.thunar-volman
      (pkgs.thunar-archive-plugin.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/libexec/thunar-archive-plugin
          cp ${pkgs.xarchiver}/libexec/thunar-archive-plugin/* \
            $out/libexec/thunar-archive-plugin/
        '';
      }))
    ];
  };

  programs.i3lock = {
    enable = true;
    package = pkgs.i3lock-color;
  };

  programs.nix-ld.enable = true;

  # SMART monitoring
  services.smartd = {
    enable = true;
    defaults.monitored = "-a -o on -S on -n standby,q";
    
    # notifications.mail = {
    #   enable = true;
    #   # Must match the account you are sending from
    #   sender = "lucas.cirille@gmail.com"; 
    #   # Where you want to receive the alert (can be the same address)
    #   recipient = "lucas.cirille@gmail.com"; 
    # };
  };

  # msmtp to actually send the email
  # programs.msmtp = {
  #   enable = true;
  #   defaults = {
  #     auth = true;
  #     tls = true;
  #     tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
  #   };
  #   accounts.default = {
  #     host = "smtp.gmail.com";       # Use smtp.protonmail.ch for Proton, etc.
  #     port = 587;
  #     user = "yourname@gmail.com";   # Your full email address
  #     # ⚠️ IMPORTANT: Do NOT use your regular password here.
  #     # Use an "App Password" generated in your Google Account security settings.
  #     password = "your_16_character_app_password"; 
  #     from = "yourname@gmail.com";   # Must match the smartd sender above
  #   };
  # };

  # System Packages & Fonts
  environment.systemPackages = with pkgs; [

    smartmontools

    gdb

    file

    polkit_gnome # gui for polkit

    # Add common runtime libraries (for nix-ld)
    stdenv.cc.cc
    zlib

    # seahorse

    arandr # Visual drag-and-drop display & projector manager
    lxrandr # Simple GUI resolution selector

    brightnessctl
    xarchiver

    ubridge # Required for connecting virtual nodes together
    vpcs # Lightweight virtual PC simulator
    dynamips # Cisco IOS router emulator (optional)
    inetutils # Provides telnet client for console access
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true; # Hard-links identical files in the store
    warn-dirty = false;
  };

  # Automatic cleanup
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # ==========================================
  # CONFIGURACIÓN EN EL HOST (FUERA DEL CONTENEDOR)
  # ==========================================
  networking.bridges.br-lab.interfaces = [ ];
  networking.interfaces.br-lab.ipv4.addresses = [
    {
      address = "10.0.10.1";
      prefixLength = 24;
    }
  ];

  # NAT dinámico: omitiendo externalInterface, NixOS usa la ruta por defecto automáticamente
  networking.nat = {
    enable = true;
    internalInterfaces = [ "br-lab" ];
    # Al no forzar externalInterface, NixOS deduce la interfaz activa con salida a internet.
  };

  # ==========================================
  # DENTRO DEL CONTENEDOR (lab-sensor)
  # ==========================================
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

  system.stateVersion = "25.11";
}
