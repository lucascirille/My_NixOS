{ config, lib, pkgs, inputs, ... }:

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
  specialisation.vm.configuration = {
    imports = [ ../../specialisations/vm.nix ];
  };

  # Display Manager (Ly) & Window Manager (Qtile)
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.qtile = {
      enable = true;
      extraPackages = python3Packages: with python3Packages; [
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

  # Enable Flatpak service and portal integration
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # Enable GNOME Keyring daemon
  services.gnome.gnome-keyring.enable = true;

  # Automatically unlock the keyring when loggin in through Ly
  security.pam.services.ly.enableGnomeKeyring = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General.AutoEnable = "false";
  };
  systemd.services.bluetooth.wantedBy = lib.mkForce [ ];

  # System User & Shell
  programs.zsh.enable = true;
  users.users.neo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "libvirtd"];
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

  # System Packages & Fonts
  environment.systemPackages = with pkgs; [
    brightnessctl
    xarchiver
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic cleanup
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };


  system.stateVersion = "25.11";
}
