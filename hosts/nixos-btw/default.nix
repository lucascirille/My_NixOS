{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/git-deploy-key.nix
    ../../modules/restic.nix
    inputs.sops-nix.nixosModules.sops # Imports the systemd sops decryption service
  ];

  nixpkgs.config.allowUnfree = true;

  # Bootloader & Quiet Boot
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
    consoleLogLevel = 0;
  };

  # Hostname & Universal Hardware Support
  networking.hostName = "nixos-btw";
  networking.networkmanager.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Specialisations (Boot choices in GRUB)
  specialisation.VM.configuration = {
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
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree ];
  };

  # Desktop Integration & Thunar File Manager
  programs.dconf.enable = true;
  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;

  programs.thunar = let
    xfce = pkgs.xfce.overrideScope (final: prev: {
      thunar-archive-plugin = prev.thunar-archive-plugin.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/libexec/thunar-archive-plugin
          cp ${pkgs.xarchiver}/libexec/thunar-archive-plugin/* \
            $out/libexec/thunar-archive-plugin/
        '';
      });
    });
  in {
    enable = true;
    plugins = [
      xfce.thunar-volman
      xfce.thunar-archive-plugin
    ];
  };

  # System Packages & Fonts
  environment.systemPackages = with pkgs; [
    brightnessctl
    xarchiver
    restic
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

  # Automatic store optimization
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "25.11";
}
