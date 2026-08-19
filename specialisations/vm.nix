{ ... }:

{
# 1. Enable Hyper-V guest integration daemons
  virtualisation.hypervGuest.enable = true;

  # 2. Enable XRDP with Qtile and audio redirection
  services.xrdp = {
    enable = true;
    defaultWindowManager = "qtile start";
    openFirewall = true;
    audio.enable = true; # Compiles and enables xrdp-pulseaudio/pipewire sinks
  };
}
