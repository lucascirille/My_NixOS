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

  # for brightness control
  hardware.i2c.enable = true;
  environment.systemPackages = [ pkgs.ddcutil ];
  users.users.neo.extraGroups = [ "i2c" ];
  # Ensure ddcutil's own advanced udev rules are loaded
  services.udev.packages = [ pkgs.ddcutil ];
}
