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
    # goverlay # More complex and more buggy if you dont configure it well
    mangojuice
    lact
  ];

# Ensure LACT daemon/service is enabled so it can listen to system events like GameMode
  services.lact.enable = true;
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];
}
