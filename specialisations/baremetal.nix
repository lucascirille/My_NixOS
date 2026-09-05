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

  # Instalar la interfaz gráfica de LACT
  environment.systemPackages = with pkgs; [
    lact
  ];

  # Habilitar el servicio del sistema (daemon) de LACT
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];

  # Desbloquear las funciones de Overclocking/Undervolting y control de ventiladores
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

}
