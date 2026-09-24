{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking.hostName = "nixos-btw";
  system.stateVersion = "25.11";

# --- TEMPORARY FIX: Gag libvirtd to break the crash loop ---
  virtualisation.libvirtd.enable = lib.mkForce false;

  # VM / Baremetal Overrides
  specialisation.baremetal.configuration = {
    imports = [ ../../specialisations/baremetal.nix ];
  };
  systemd.services.libvirtd.unitConfig.ConditionVirtualization = "!vm";
  virtualisation.hypervGuest.enable = lib.mkDefault true;

}
