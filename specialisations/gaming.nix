# { config, pkgs, lib, ... }:
#
# {
#   # string generico para potenciar placas amd, verificar si funciona para su modelo
#   services.xserver.videoDrivers = [ "amdgpu" ];
#
#   boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
#
#   hardware.graphics = {
#       enable = true;
#       enable32Bit = true;
#       extraPackages = with pkgs; [
#         intel-media-driver # aceleracion por hardware intel
#       ];
#     };
#
#   # herramientas exclusivas para jugar
#   environment.systemPackages = with pkgs; [
#     mangohud
#     mangojuice
#     lact
#   ];
#
#   # habilita el servicio de lact correctamente de forma nativa
#   services.lact.enable = true;
#
#   # fix: inject systemd (for busctl) and system wrappers (for sudo)
#   # so lact can run `sudo -u user busctl` to reach gamemode dbus.
#   systemd.services.lactd.path = with pkgs; [ 
#     systemd 
#     gamemode 
#     bash
#     "/run/wrappers"
#   ];
#
#
# }

{ config, pkgs, ... }:

{
  # 1. Instalar la interfaz gráfica de LACT
  environment.systemPackages = with pkgs; [
    lact
  ];

  # 2. Habilitar el servicio del sistema (daemon) de LACT
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];

  # 3. Desbloquear las funciones de Overclocking/Undervolting y control de ventiladores
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
  ];
}
