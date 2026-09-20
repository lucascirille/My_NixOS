{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ../../modules/virt-lab.nix
    ../../modules/containers.nix
  ];

  networking.hostName = "nixos-btw";
  system.stateVersion = "25.11";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  virtualisation.libvirtd.enable = lib.mkForce false;

  # VM / Baremetal Overrides
  specialisation.baremetal.configuration = {
    imports = [ ../../specialisations/baremetal.nix ];
  };
  systemd.services.libvirtd.unitConfig.ConditionVirtualization = "!vm";
  virtualisation.hypervGuest.enable = lib.mkDefault true;

}
