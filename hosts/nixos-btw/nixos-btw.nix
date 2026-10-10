{config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking.hostName = "nixos-btw";
  system.stateVersion = "25.11";

  

  # VM / Baremetal Overrides
  specialisation.baremetal.configuration = {
    imports = [ ../../specialisations/baremetal.nix ];
  };
  systemd.services.libvirtd.unitConfig.ConditionVirtualization = "!vm";
  virtualisation.hypervGuest.enable = lib.mkDefault true;

  boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelModules = [ "i2c-dev" "ddcci_backlight" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];

}
