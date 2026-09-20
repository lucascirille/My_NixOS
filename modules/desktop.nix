{ config, lib, pkgs, ... }: {
  stylix = {
    enable = true;
    image = ../home/assets/wallpapers/current.jpg;
    polarity = "dark";
    fonts = {
      monospace = { package = pkgs.nerd-fonts.jetbrains-mono; name = "JetBrainsMono Nerd Font"; };
      sansSerif = { package = pkgs.inter; name = "Inter"; };
      sizes = { applications = 12; terminal = 14; };
    };
    cursor = { package = pkgs.bibata-cursors; name = "Bibata-Modern-Classic"; size = 24; };
  };

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

  services.gnome.at-spi2-core.enable = true;
  services.blueman.enable = true;
  services.dbus.enable = true;
  
  programs.dconf.enable = true;
  programs.xfconf.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;

  services.xserver = {
    enable = true;
    xkb = { layout = "us"; variant = "altgr-intl"; };
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    updateDbusEnvironment = true;
    windowManager.qtile = {
      enable = true;
      extraPackages = python3Packages: with python3Packages; [ qtile-extras ];
    };
    displayManager.sessionCommands = ''
      ${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
      ${pkgs.systemd}/bin/systemctl --user start graphical-session.target
    '';
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      brightness_down_key = "F5";
      brightness_up_key = "F6";
      brightness_down_cmd = "${pkgs.brightnessctl}/bin/brightnessctl set 20%-";
      brightness_up_cmd = "${pkgs.brightnessctl}/bin/brightnessctl set 20%+";
    };
  };

  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          qtile = python-prev.qtile.overrideAttrs (old: { doCheck = false; pytestCheckPhase = "echo 'Skipping Qtile tests...'"; });
          qtile-extras = python-prev.qtile-extras.overrideAttrs (old: { doCheck = false; pytestCheckPhase = "echo 'Skipping Qtile-extras tests...'"; });
        })
      ];
    })
  ];

  services.flatpak = {
    enable = true;

    # Declaramos los repositorios que queremos usar
    remotes = lib.mkOptionDefault [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # Declaramos exactamente qué aplicaciones instalar
    packages = [
      "com.github.tchx84.Flatseal"
      "net.davidotek.pupgui2"
      "com.usebottles.bottles"
      "org.vinegarhq.Sober"
    ];

    # Limpieza automática de apps que quites de la lista
    uninstallUnmanaged = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  services.gnome.gnome-keyring.enable = false;
  security.pam.services.ly.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General.AutoEnable = "false";
  };
  systemd.services.bluetooth.wantedBy = lib.mkForce [ ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ intel-compute-runtime pocl rocmPackages.clr.icd ];
  };

  programs.thunar = {
    enable = true;
    plugins = [
      pkgs.thunar-volman
      (pkgs.thunar-archive-plugin.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/libexec/thunar-archive-plugin
          cp ${pkgs.xarchiver}/libexec/thunar-archive-plugin/* $out/libexec/thunar-archive-plugin/
        '';
      }))
    ];
  };

  programs.nm-applet.enable = true;

  programs.i3lock = { enable = true; package = pkgs.i3lock-color; };
  
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
