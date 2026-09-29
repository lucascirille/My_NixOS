{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "25.11";
  
  # TPM 2.0 support
  security.tpm2.enable = true;
  # enables Software TPM (swtpm) for VM security.
  virtualisation.libvirtd.qemu.swtpm.enable = true;

}
