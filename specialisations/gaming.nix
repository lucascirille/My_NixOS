{ config, pkgs, lib, ... }:

{
  # ---- SOLO PARA AMD ------
  hardware.amdgpu.overdrive.enable = true;
  # String generico para potenciar placas AMD, verificar si funciona para su modelo
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

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
    mangojuice
    lact
  ];

  # Habilita el servicio de LACT correctamente de forma nativa
  services.lact.enable = true;

# FIX: Inject systemd (for busctl) and system wrappers (for sudo)
  # so LACT can run `sudo -u user busctl` to reach GameMode DBus.
  systemd.services.lactd.path = with pkgs; [ 
    systemd 
    gamemode 
    bash
    "/run/wrappers"
  ];

}
