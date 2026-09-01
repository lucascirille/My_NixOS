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
      "--exclude-larger-than"
      "1G"
      "--one-file-system"
    ];

    paths = [
      "/home"
      "/etc/ssh"
      # "/var/lib"
    ];

    exclude = [
      # Specific user paths & syncs
      "/home/*/Documents/second_brain" # Backed up via OneDrive
      "/home/*/Downloads"

      # Standard system & user caches
      "**/.cache"
      "**/.local/share/Trash"
      "/var/cache"
      "/var/tmp"
      "/var/log/journal"

      # Flatpak runtimes (User data preserved in ~/.var/app)
      "**/.local/share/flatpak"
      "/var/lib/flatpak"

      # Games, shader caches, and compatibility data
      "/home/*/Games"
      "**/.local/share/Steam"
      "**/.steam"

      # Browser Caches
      "/home/*/.config/BraveSoftware/Brave-Browser/*/Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/*/Code Cache"
      "/home/*/.config/BraveSoftware/Brave-Browser/*/GPUCache"

      # Developer build caches & virtual envs
      "**/node_modules"
      "**/target"
      "**/.direnv"
      "**/.venv"
      "**/.npm"
      "**/.bun"
      "**/.local/share/pnpm"
      "/home/*/.cargo"
      "/home/*/.rustup"

      # Container, VM, and Virtualization storage
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"
      "/var/lib/systemd/coredump"
      "**/.local/share/containers"

      # Large disk images and media files
      "**/*.qcow2"
      "**/*.img"
      "**/*.iso"
      "**/*.vmdk"
      "**/*.raw"
      "**/*.mp4"
      "**/*.mkv"
    ];

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
