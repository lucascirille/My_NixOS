{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ../../modules/virt-lab.nix
    # ../../modules/hardening.nix
    ../../modules/containers.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "25.11";

  security.tpm2.enable = true;


}
