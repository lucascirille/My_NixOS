{ pkgs, ... }:

{

  # SMART monitoring (not for VM)
  services.smartd = {
    enable = true;
    defaults.monitored = "-a -o on -S on -n standby,q";

    # Pop-up notifications
    notifications.systembus-notify.enable = true;

    # Print message to any open terminal widows
    notifications.wall.enable = true;

  };

  virtualisation.hypervGuest.enable = false;

  hardware.amdgpu.overdrive.enable = true;

  # Enable the official LACT module (handles packages, services, and writable paths automatically)
  services.lact.enable = true;

  # Desbloquear las funciones de Overclocking/Undervolting y control de ventiladores
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

}
