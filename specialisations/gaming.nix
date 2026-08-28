{ config, pkgs, lib, ... }:

{
  # Inyectamos los drivers y permisos físicos solo cuando inicias en este modo
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  # Herramientas exclusivas para jugar
  environment.systemPackages = with pkgs; [
    mangohud
    goverlay
    lact
  ];

  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];
}
