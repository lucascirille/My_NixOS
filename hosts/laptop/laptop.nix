{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "25.11";

  security.tpm2.enable = true;


}
