{ config, pkgs, lib, ... }:

{
  # string generico para potenciar placas amd, verificar si funciona para su modelo
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # aceleracion por hardware intel
      ];
    };

  # herramientas exclusivas para jugar
  environment.systemPackages = with pkgs; [
    mangohud
    mangojuice
    lact
  ];

  # habilita el servicio de lact correctamente de forma nativa
  services.lact.enable = true;

  # fix: inject systemd (for busctl) and system wrappers (for sudo)
  # so lact can run `sudo -u user busctl` to reach gamemode dbus.
  systemd.services.lactd.path = with pkgs; [ 
    systemd 
    gamemode 
    bash
    "/run/wrappers"
  ];

  programs.gamemode = {
    enable = true;
    settings = {
      custom = {
        start = ''
          # Cambia a modo manual y aplica tu perfil de rendimiento alto / OC
          echo manual > /sys/class/drm/card1/device/power_dpm_force_performance_level
        '';
        end = ''
          # Devuelve el control de energía al kernel (vuelve a los valores por defecto del sistema)
          echo auto > /sys/class/drm/card1/device/power_dpm_force_performance_level
        '';
      };
    };
  };

}
