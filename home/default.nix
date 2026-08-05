{ config, pkgs, ... }:

{
  home.username = "neo";
  home.homeDirectory = "/home/neo";
  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
  };
  home.packages = with pkgs; [
    btop
    fastfetch
    ghostty
    wget
    brave
    rofi
    pamixer
    pavucontrol
    playerctl
    xclip
    libnotify
    unzip
    zip
    p7zip
  ];
  home.stateVersion = "25.05";
  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
  };
  xdg.configFile."qtile".source = ./config/qtile;
  xdg.configFile."ghostty".source = ./config/ghostty;
  xdg.configFile."nvim".source = ./config/nvim;
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Lucas Cirille";
        email = "lucas.cirille@gmail.com";
      };

      init.defaultBranch = "main";
    };
  };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
      theme = "robbyrussell";
    };

  initContent = ''
nos() {
  local orig_dir="$PWD"
  cd ~/.dotfiles || return 1

  # 1. Pull latest changes from remote, autostashing any local edits
  echo "📥 Fetching and integrating remote changes..."
  if ! git pull --rebase --autostash origin main; then
    echo "❌ Git pull failed! Please resolve merge conflicts before building."
    cd "$orig_dir"
    return 1
  fi

  # 2. Stage all untracked/modified files (REQUIRED for Flakes to see new files)
  git add .

  # 3. Try to rebuild the system FIRST
  echo "🔨 Building NixOS configuration..."
  if sudo nixos-rebuild switch --flake ~/.dotfiles#nixos-btw; then
    echo "✅ Build successful!"

    # 4. Only commit & push IF the rebuild succeeded and there are changes
    if ! git diff-index --quiet HEAD --; then
      echo "📦 Committing and pushing working configuration to Git..."
      git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
      git push
    else
      echo "🧹 Working tree clean. Nothing to commit."
    fi
  else
    echo "❌ Rebuild failed! Aborting Git commit and push."
    cd "$orig_dir"
    return 1
  fi

  cd "$orig_dir"
}
  '';

    shellAliases = {
      btw = "echo i use nixos, btw";
      not = "sudo nixos-rebuild test --flake ~/.dotfiles#nixos-btw";
      nop = "sudo nix-collect-garbage --delete-older-than 7d && sudo nix store optimise";
      nv = "nvim";
    };
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";

      # Directory
      directory = {
        style = "bold blue";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      # Git branch
      git_branch = {
        symbol = " ";
        style = "bold green";
      };

      # Git status (very useful)
      git_status = {
        style = "yellow";
      };

      # Command duration (only shows if slow)
      cmd_duration = {
        min_time = 500;
        format = "⏱ [$duration](bold yellow) ";
      };

      # Prompt character
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 200;
        origin = "top-right";
        offset = "20x20"; # Slightly tighter offset

        # The "Modern" look
        corner_radius = 10; # Rounded corners
        frame_width = 2; # A thin border
        padding = 15; # Internal space
        horizontal_padding = 15;
        separator_height = 2;

        font = "JetBrains Mono 10";
        frame_color = "#61afef"; # A nice blue border (One Dark style)
      };

      urgency_normal = {
        background = "#282c34";
        foreground = "#abb2bf";
        timeout = 5;
      };
      # This rule applies only to the volume "stack-tag"
      "volume_bar" = {
        stack_tag = "volume";
        summary = "Volume";
        history_ignore = "yes"; # Don't save volume changes in notification history
        alignment = "center";
      };
    };
  };
}
