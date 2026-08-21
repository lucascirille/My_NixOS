{
  config,
  pkgs,
  username,
  ...
}:



let
  # Define the absolute path to your dotfiles directory
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";
    # Tells 'nh' where your flake lives so you don't need to pass paths manually
    NH_FLAKE = "${config.home.homeDirectory}/.dotfiles";
  };
  home.packages = with pkgs; [
    keepassxc

    ouch # Unified compression/decompression tool
    cava # PipeWire-compatible audio visualizer

    docker-compose
    lazydocker # Terminal UI for Docker

    zip
    unzip
    p7zip
    gnutar

    vesktop
    spotify

    zathura # Minimalist PDF viewer
    foliate # Dedicated e-book reader

    nsxiv # Fast, lightweight image viewer with gallery mode
    mpv # Minimalist, high-performance video player

    # Screenshot tools
    maim
    xdotool

    # Virtualization
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice

    # Networking lab
    gns3-gui
    gns3-server

    nh
    nix-output-monitor
    btop
    fastfetch
    ghostty
    wget
    rofi
    pamixer
    pavucontrol
    playerctl
    xclip
    libnotify
    bubblewrap
  ];

  # Configure virt-manager default connection URI via dconf
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  home.stateVersion = "25.11";

  gtk = {
    enable = true;

    gtk4.theme = config.gtk.theme;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
  };
  xdg.configFile."qtile".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/config/qtile";
  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/config/ghostty";
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/config/nvim";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png" = [ "nsxiv.desktop" ];
      "image/jpeg" = [ "nsxiv.desktop" ];
      "image/gif" = [ "nsxiv.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/mkv" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];

      # PDFs & PostScript
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/postscript" = [ "org.pwmt.zathura.desktop" ];

      # E-books & Comics
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "application/x-mobipocket-ebook" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "application/vnd.amazon.ebook" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "application/vnd.comicbook+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
    };
  };

programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Lucas Cirille";
        email = "lucas.cirille@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "Catppuccin-mocha";
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [
            "#89b4fa"
            "bold"
          ];
          inactiveBorderColor = [ "#6c7086" ];
        };
      };
      git = {
        # Nueva sintaxis de LazyGit
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
      };
    };
  };



programs.vscode = {
  enable = true;
  package = pkgs.vscode.override {
    commandLineArgs = "--password-store=gnome-libsecret";
  };

  profiles.default.extensions = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide
    dracula-theme.theme-dracula
    vscodevim.vim
  ];

  profiles.default.userSettings = {
    "workbench.colorTheme" = "Dracula Theme";
    "editor.formatOnSave" = true;
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
  };
};




programs.keepassxc = {
  enable = true;
};

  programs.tmux = {
    enable = true;
    mouse = true;
    baseIndex = 1;
    keyMode = "vi";
    terminal = "tmux-256color";
    prefix = "C-a";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_number_position "right"
          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_default_text "#W"
          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_window_current_text "#W"
          set -g @catppuccin_status_modules_right "directory user host session"
          set -g @catppuccin_status_fill "icon"
          set -g @catppuccin_status_connect_separator "no"
          set -g @catppuccin_directory_text "#{pane_current_path}"
        '';
      }
    ];

    extraConfig = ''
      unbind C-b
      bind C-a send-prefix

      # Window & pane index
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set -g renumber-windows on
      set -g status-position top
      set -s escape-time 0

      # Clear screen
      unbind-key -T copy-mode-vi C-l
      unbind-key -T root C-l
      bind-key -n C-l send-keys C-l

      # Pane navigation (Vim style with prefix)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Alt + hjkl to switch panes directly without prefix
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      # Create windows/panes in current working directory
      bind c new-window -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Copy mode (Vim bindings)
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    '';
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

              echo "📥 Fetching and integrating remote changes..."
              if ! git pull --rebase --autostash origin main; then
                echo "❌ Git pull failed! Please resolve merge conflicts before building."
                cd "$orig_dir"
                return 1
              fi

              git add .

              echo "🔨 Building NixOS configuration with nh..."
              # nh automatically uses nix-output-monitor for pretty tree output
              if nh os switch; then
                echo "✅ Build successful!"

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
      not = "nh os test"; # Uses nh to test changes cleanly
      nop = "nh clean all --keep 5"; # Clean garbage safely
      nv = "nvim";
      better-sops = "sudo SOPS_AGE_KEY=$(sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key) ${pkgs.sops}/bin/sops";
    };
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
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

  # --- User Space Hardening ---
  # GPG configuration with minimal key leakage
  programs.gpg = {
    enable = true;
    settings = {
      no-emit-version = true;
      no-comments = true;
      keyid-format = "0xlong";
      with-fingerprint = true;
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
    };
  };

  # Harden Brave Browser execution
  # This adds sandboxing flags to your Brave shortcut
programs.chromium = {
  enable = true;
  package = pkgs.brave;
  commandLineArgs = [
    "--enable-features=UseOzonePlatform"
    "--ozone-platform=x11"
    "--password-store=gnome-libsecret"
    "--no-default-browser-check"
    "--disable-reading-from-canvas"
    "--no-pings"
  ];
};

services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 200;
        origin = "top-right";
        offset = "20x20";
        corner_radius = 10;
        frame_width = 2;
        padding = 15;
        horizontal_padding = 15;
        separator_height = 2;
        font = "JetBrains Mono 10";
        frame_color = "#61afef";
      };

      urgency_normal = {
        background = "#282c34";
        foreground = "#abb2bf";
        timeout = 5;
      };

      "volume_bar" = {
        stack_tag = "volume";
        summary = "Volume";
        history_ignore = "yes";
        alignment = "center";
      };

      # Style Flameshot popups cleanly inside Dunst
      "flameshot_custom" = {
        appname = "Flameshot";
        timeout = 2;
        history_ignore = true;
        frame_color = "#9ece6a"; # Green accent border
      };

    };
  };



systemd.user.services.keepassxc = {
  Unit = {
    Description = "KeePassXC password manager daemon";
    After = [ "graphical-session.target" ];
  };
  Service = {
    ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
    ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized";
    Restart = "on-failure";
    Environment = [
      "DISPLAY=:0"
      "QT_QPA_PLATFORM=xcb"
    ];
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};

}
