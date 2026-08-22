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
    initialize = true;

    repository = "s3:https://708aebc1307b24a58bb55b911786fe4e.r2.cloudflarestorage.com/fallout-shelter";
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.secrets.restic_env.path;

    extraBackupArgs = [
      "--compression"
      "auto"
      "--exclude-caches"
      # Exclude any single file larger than 500 MB (adjust as needed)
      "--exclude-larger-than"
      "1G"
    ];

    paths = [
      "/home"
      "/etc/ssh"
      "/var/lib"
    ];

    exclude = [
      # System & standard caches
      "/home/*/Documents/second_brain" # My notations already backup on Onedrive
      "/home/*/.cache"
      "/home/*/.local/share/Trash"
      "/home/*/.local/share/containers"
      "/home/*/.local/share/flatpak"
      "/home/*/Downloads"
      "/var/cache"
      "/var/tmp"

      # Steam games, shader caches, and compatibility data
      "/home/*/.local/share/Steam"
      "/home/*/.steam"
      "**/.local/share/Steam"
      "**/.steam"

      # Brave Browser Caches
      "/home/*/.config/BraveSoftware/Brave-Browser/*/Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/*/Code Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/*/GPUCache"

      # Developer build caches & virtual envs
      "**/node_modules"
      "**/target"
      "**/.direnv"
      "**/.venv"
      "/home/*/.cargo"
      "/home/*/.rustup"

      # Container, VM, and Virtualization storage (Crucial)
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"
      "/var/lib/flatpak"
      "/var/lib/systemd/coredump"

      # Large disk images and media extensions anywhere in the system
      "**/*.qcow2"
      "**/*.img"
      "**/*.iso"
      "**/*.vmdk"
      "**/*.raw"
      "**/*.mp4"
      "**/*.mkv"
    ];

    # Stricter retention rules to stay well under Cloudflare R2's 10 GB limit
    pruneOpts = [
      "--keep-daily=3"
      "--keep-weekly=2"
      "--keep-monthly=1"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
