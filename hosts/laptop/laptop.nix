{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "25.11";

services.power-profiles-daemon.enable = false;

services.tlp = {
  enable = true;
  settings = {
    # Governor settings
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    # Energy Performance Preference (EPP)
    # 'balance_power' is usually the sweet spot for modern CPUs on battery. 
    # It saves power without making the UI lag.
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

    # Allow the CPU to boost when needed, but prioritize lower frequencies
    CPU_MIN_PERF_ON_AC = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MIN_PERF_ON_BAT = 0;
    # 70-80% is a much better limit. It prevents extreme thermal throttling 
    # but still lets the system feel fast and responsive.
    CPU_MAX_PERF_ON_BAT = 75; 
  };
};

services.libinput = {
  enable = true;
  touchpad = {
    disableWhileTyping = true;
  };
};
  
  # TPM 2.0 support
  security.tpm2.enable = true;
  # enables Software TPM (swtpm) for VM security.
  virtualisation.libvirtd.qemu.swtpm.enable = true;

}
