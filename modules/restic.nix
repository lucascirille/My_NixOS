{ config, pkgs, ... }:

{
  # 1. Register sops secrets for Restic
  sops.secrets.restic_password = { };
  sops.secrets.restic_env = { };

  # Add restic and a custom helper wrapper
  environment.systemPackages = [
    pkgs.restic
    (pkgs.writeShellScriptBin "restic-daily" ''
      set -a
      source "${config.sops.secrets.restic_env.path}"
      set +a

      exec ${pkgs.restic}/bin/restic \
        -r "${config.services.restic.backups.daily.repository}" \
        --password-file "${config.sops.secrets.restic_password.path}" \
        "$@"
    '')
  ];

  # 2. Configure Restic Backup Service
  services.restic.backups.daily = {
    initialize = true; # Automatically initializes R2 repository if it doesn't exist

    repository = "s3:https://708aebc1307b24a58bb55b911786fe4e.r2.cloudflarestorage.com/fallout-shelter";
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.secrets.restic_env.path;

    # Enable automatic compression for backups
    extraBackupArgs = [
      "--compression"
      "auto"
    ];

    paths = [
      "/home" # User personal data, configs, and documents
      "/etc/ssh" # NixOS system configuration
      "/var/lib" # Stateful system data (Docker, databases, VMs, sops keys)
    ];

    exclude = [
      # System & standard caches
      "/home/*/.cache"
      "/home/*/.local/share/Trash"
      "/var/cache"
      "/var/tmp"

      # Brave Browser Caches
      "/home/*/.config/BraveSoftware/Brave-Browser/*/Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/*/Code Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/*/GPUCache"

      # Developer build caches & virtual envs (Recursive match)
      "**/node_modules"
      "**/target"
      "**/.direnv"
      "**/.venv"

      # Container/VM storage
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"
    ];

    # Retention rules
    pruneOpts = [
      "--keep-daily=7"
      "--keep-weekly=4"
      "--keep-monthly=12"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
