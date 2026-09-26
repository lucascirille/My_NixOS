{ config, lib, pkgs, ... }: {
  # Bootloader & Quiet Boot
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
      timeout = 3600;
    };
    kernel = {
    sysctl."kernel.sysrq" = 1; # Enable all Magic SysRq functions
    sysctl = { "vm.max_map_count" = 262144; };
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    kernelParams = [ "quiet" "loglevel=4" "systemd.show_status=true" ];
    consoleLogLevel = 4;
  };

  security.tpm2.enable = lib.mkDefault false;
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Nix Settings & GC
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    warn-dirty = false;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.logind.powerKey = "ignore";

  # Common SOPS Setup
  sops = {
    defaultSopsFile = ../secrets/hosts/nixos-btw.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "neo_password".neededForUsers = true;
      "hermes-env".owner = config.users.users.neo.name; 
      "gcalcli_oauth" = {
        sopsFile = ../secrets/hosts/gcalcli_oauth.enc;
        format = "binary";
        path = "/home/neo/.local/share/gcalcli/oauth";
        mode = "0600";
        owner = config.users.users.neo.name;
      };
    };
  };

  # Users
  users.mutableUsers = false;
  users.users.neo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "render" "libvirtd" "wireshark" "ubridge" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree ];
    hashedPasswordFile = config.sops.secrets."neo_password".path;
    linger = true;
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;
  networking.nameservers = [];
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  environment.systemPackages = with pkgs; [
    ncdu smartmontools gdb file polkit_gnome
    stdenv.cc.cc zlib arandr lxrandr brightnessctl xarchiver
    ubridge vpcs dynamips inetutils
  ];
}
