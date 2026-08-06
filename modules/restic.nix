{ config, pkgs, ... }:

{
  # 1. Register sops secrets for Restic
  sops.secrets."restic_password" = { };
  sops.secrets."restic_env" = { };

  # 2. Configure Restic Backup Service
  services.restic.backups.daily = {
    initialize = true; # <-- Automatically initializes R2 repository if it doesn't exist

    repository = "s3:https://708aebc1307b24a58bb55b911786fe4e.r2.cloudflarestorage.com/fallout-shelter";  
    passwordFile = config.sops.secrets."restic_password".path;
    environmentFile = config.sops.secrets."restic_env".path;

    paths = [
      "/home"                      # User personal data, configs, and documents
      "/etc/nixos"                 # Standard path if dotfiles live here (ignore if elsewhere)
      "/var/lib"                   # Stateful system data (Docker, databases, VMs, sops keys)
    ];

    exclude = [
      # System & standard cache
      "/home/*/.cache"
      "/home/*/.local/share/Trash"
      "/var/cache"
      "/var/tmp"
    
      # Brave Browser Caches
      "/home/*/.config/BraveSoftware/Brave-Browser/Default/Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/Default/Code Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/Default/GPUCache"
      "/home/*/.config/BraveSoftware/Brave-Browser/System Profile/Cache"
    
      # Developer build caches & virtual envs
      "/home/*/**/node_modules"
      "/home/*/**/target"
      "/home/*/**/.direnv"
      "/home/*/**/.venv"
    
      # Container/VM storage
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"
    ];

    # Retention rules (keep last 7 daily, 4 weekly, 12 monthly backups)
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
