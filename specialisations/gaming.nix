{ config, pkgs, lib, ... }:

{
  # Inyectamos los drivers y permisos físicos solo cuando inicias en este modo AMD
  services.xserver.videoDrivers = [ "amdgpu" ];

  # String generico para potenciar placas AMD, verificar si funciona para su modelo
  # boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # aceleracion por hardware Intel
      ];
    };

  # Herramientas exclusivas para jugar
  environment.systemPackages = with pkgs; [
    mangohud
    goverlay
    lact
  ];

  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];
}
