{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "25.11";

  services.tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

    CPU_MIN_PERF_ON_AC = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MIN_PERF_ON_BAT = 0;
    CPU_MAX_PERF_ON_BAT = 30;
  };
};
  
  # TPM 2.0 support
  security.tpm2.enable = true;
  # enables Software TPM (swtpm) for VM security.
  virtualisation.libvirtd.qemu.swtpm.enable = true;

}
