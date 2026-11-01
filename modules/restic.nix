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
      "max"
      "--exclude-caches"
      "--exclude-larger-than"
      "500M"
      "--one-file-system"
    ];

    paths = [
      "/home"
      "/etc/ssh"
    ];

    exclude = [
      # Specific user paths & syncs
      "/home/*/Documents/second_brain"
      "/home/*/Downloads"

      # Standard system, Nix, & user caches
      "**/.cache"
      "**/.local/share/Trash"
      "**/.local/share/nix"
      "**/.local/state/nix"
      "/var/cache"
      "/var/tmp"
      "/var/log/journal"

      # Flatpak runtimes AND per-app caches inside ~/.var/app
      "**/.local/share/flatpak"
      "/var/lib/flatpak"
      "**/.var/app/*/cache"
      "**/.var/app/**/Cache"
      "**/.var/app/**/Code Cache"
      "**/.var/app/**/GPUCache"

      # Rootless Docker & UMU
      "/home/*/.local/share/docker"
      "/home/*/.local/share/umu"

      # Games, shader caches, and compatibility data
      "/home/*/Games"
      "**/.local/share/Steam"
      "**/.steam"

      # All Chromium, Brave, & Electron app caches (Discord, Obsidian, VS Code, etc.)
      "**/.config/**/Cache"
      "**/.config/**/Code Cache"
      "**/.config/**/GPUCache"
      "**/.config/**/DawnCache"
      "**/.config/**/Service Worker/CacheStorage"
      "**/.config/Code/CachedData"
      "**/.config/Code/CachedExtensionVSIXs"

      # Developer build caches, IDEs, & virtual envs
      "**/node_modules"
      "**/target"
      "**/.direnv"
      "**/.venv"
      "**/.npm"
      "**/.bun"
      "**/.local/share/pnpm"
      "**/.vscode/extensions"
      "**/.cursor/extensions"
      "/home/*/.cargo"
      "/home/*/.rustup"
      "/home/*/go/pkg"

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
      "--group-by=host"
      "--keep-daily=3"
      "--keep-weekly=2"
      "--keep-monthly=1"
      "--max-unused=1%"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
