{ ... }:

{
virtualisation.hypervGuest.enable = true;

services.xrdp = {
    enable = true;
    defaultWindowManager = "qtile start";
    openFirewall = true;
    audio.enable = true;
    extraConfDirCommands = ''
      substituteInPlace $out/xrdp.ini \
        --replace "port=3389" "port=vsock://-1:3389"
    '';
  };
}
