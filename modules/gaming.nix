{ pkgs, ... }: {
  programs.gamemode.enable = true;
  
  programs.steam = {
    enable = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  system.userActivationScripts.steamDevCfg.text = ''
    mkdir -p "$HOME/.local/share/Steam"
    echo "unShaderBackgroundProcessingThreads $(nproc)" > "$HOME/.local/share/Steam/steam_dev.cfg"
  '';

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [ wlrobs obs-backgroundremoval obs-pipewire-audio-capture ];
  };
}
