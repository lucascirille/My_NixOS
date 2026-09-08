{
  config,
  pkgs,
  username,
  inputs,
  osConfig,
  ...
}:

let
  # Define the absolute path to your dotfiles directory
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  imports = [
    inputs.hermes-agent.homeManagerModules.default
  ];
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.sessionVariables = {
    SUDO_EDITOR = "nvim";
    EDITOR = "nvim";
    # Tells 'nh' where your flake lives so you don't need to pass paths manually
    NH_FLAKE = "${config.home.homeDirectory}/.dotfiles";
  };
  home.packages = with pkgs; [

    sqlite

    heroic # Epic Launcher for Linux

    qdiskinfo
    fio

    # Neovim & tooling
    neovim
    nil
    lua-language-server
    ripgrep
    fd
    gcc
    gnumake
    tree-sitter
    silicon
    texliveMedium
    nodejs_22

    mat2 # CLI tool to strip metadata (GPS, EXIF) from files/images before sharing

    keepassxc


    # --- Ciberseguridad (Host Seguro) ---
    burpsuite # Proxy e interceptor web
    bloodhound # Analizador de grafos para Active Directory
    hashcat # Rompedor de hashes acelerado por GPU
    # ------------------------------------

    ouch # Unified compression/decompression tool

    docker-compose

    zip
    unzip
    p7zip
    gnutar

    vesktop
    spotify

    foliate # Dedicated e-book reader

    nsxiv # Fast, lightweight image viewer with gallery mode

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
    wget
    pamixer
    pavucontrol
    xclip
    libnotify
    bubblewrap

    mangojuice
  ];

  programs.keepassxc.enable = true;
  
  programs.ttyper.enable = true;

    programs.mangohud = {
    enable = true;

    settings = {
      fps = true;
      frametime = true;
      gpu_stats = true;
      cpu_stats = true;
      ram = true;
      vram = true;
      temperature = true;
    };
  };

  programs.mpv.enable = true;
  programs.feh.enable = true;
  programs.cava.enable = true;
  programs.rofi.enable = true;
  programs.fastfetch.enable = true;
  programs.lazydocker.enable = true;

  programs.hermes-agent = {
      enable = true;
      desktop.enable = true;
  };


  services.hermes-agent = {
    enable = true;
    gateway.enable = true;
    backend.mode = "serve"; 
    backend.port = 9119;

    hermesHomeFiles."SOUL.md" = ''
      Act as a "caveman" AI. Your primary directive is extreme efficiency and brevity.
      Rules:
      1. No pleasantries, greetings, or conclusions.
      2. No filler words. Use the absolute minimum number of tokens required.
      3. If asked for code or a command, output ONLY the code/command.
      4. Be direct, blunt, and factual.
      Respond in the language of the prompt.
    '';

    mcpServers = {
      "filesystem" = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/neo" ];
      };
    };
    
    settings = {
      model = {
        default = "openrouter/free";
        provider = "openrouter"; 
        extra_body = {
          reasoning = {
            effort = "none";
          };
        };
      };
      fallback_model = {
        model = "gemini-2.5-flash";
        provider = "gemini";
        base_url = "https://generativelanguage.googleapis.com/v1beta";
      };
      kanban = {
        dispatch_in_gateway = true;
        dispatch_interval_seconds = 10;
      };
      browser = {
        backend = "local";
        headless = false;
        cdp_url = "http://127.0.0.1:9222";
      };

      toolsets = [ "all" ];

      computer_use = {
        native_wayland = true;
        permission_mode = "standard";
      };

      extraPackages = with pkgs; [
        uv        
        chromium  
        nodejs
        xdotool
        xclip
        maim
        grim
        slurp
        ydotool
        wl-clipboard
      ];
    };

    environmentFiles = [
      osConfig.sops.secrets."hermes-env".path
    ];
  };

  services.flameshot.enable = true;
  services.playerctld.enable = true;

  programs.ghostty = {
    enable = true;
    settings = {
      command = "tmux";

      # We use a double backslash here so Nix outputs it as \x00
      keybind = "ctrl+space=text:\\x00";

      # Performance & Startup
      scrollback-limit = 10000000;

      # Visuals & Compositing (zero transparency/blur overhead)
      background-opacity = 1.0;
      background-blur = 0;

      # Minimalism (no window decorations or tabs)
      window-decoration = false;
      gtk-tabs-location = "hidden";
      window-padding-x = 0;
      window-padding-y = 0;
      window-padding-balance = false;
    };
  };
  stylix.targets.ghostty.enable = false;

  programs.zathura.enable = true;

  # Configure virt-manager default connection URI via dconf
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  programs.btop.enable = true;

  home.stateVersion = "25.11";

  gtk = {
    enable = true;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

  };

  xdg.configFile."qtile".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/config/qtile";
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/config/nvim";

  xdg.configFile."flameshot/flameshot.ini".text = ''
    [General]
    showStartupLaunchMessage=false
  '';

  # --- Accesos Directos Personalizados ---
  xdg.desktopEntries = {
    bloodhound = {
      name = "BloodHound";
      genericName = "Active Directory Analyzer";
      exec = "BloodHound";
      terminal = false;
      categories = [
        "Network"
        "Security"
      ];
      comment = "Analizador de rutas de ataque con grafos";
    };
  };

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

  programs.obsidian = {
    enable = true;

    vaults.notes = {
      target = "Documents/second_brain";
    };

    defaultSettings = {
      app = {
        alwaysUpdateLinks = true;
        spellcheck = true;
      };

      appearance = {
        accentColor = "#7aa2f7";
      };

      corePlugins = [
        "backlink"
        "bookmarks"
        "command-palette"
        "daily-notes"
        "file-explorer"
        "global-search"
        "outgoing-link"
        "page-preview"
        "switcher"
        "tag-pane"
        "templates"
        "word-count"
      ];
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Lucas Cirille";
        email = "lucas.cirille@gmail.com";
        signingkey = "~/.ssh/id_ed25519.pub";
      };
      gpg = {
        format = "ssh";
      };
      commit = {
        gpgsign = true;
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
      "editor.formatOnSave" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
    };
  };


programs.tmux = {
    enable = true;
    mouse = true;
    baseIndex = 1;
    keyMode = "vi";
    terminal = "tmux-256color";
    prefix = "C-a";

    extraConfig = ''
      # Soporte True Color (necesario para Stylix/Base16)
      set-option -sa terminal-features ',xterm-256color:RGB'

      # Empezar a numerar los paneles en 1 y renumerar ventanas al cerrar
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # Clear the default left side
      set-option -g status-left ""

      # Active window (The one you are currently using)
      set-window-option -g window-status-current-format "#[fg=#${config.lib.stylix.colors.base0D},bg=default]#[fg=#${config.lib.stylix.colors.base00},bg=#${config.lib.stylix.colors.base0D},bold] #I  #W #[fg=#${config.lib.stylix.colors.base0D},bg=default] "

      # Inactive windows (The ones running in the background)
      set-window-option -g window-status-format "#[fg=#${config.lib.stylix.colors.base03},bg=default]#[fg=#${config.lib.stylix.colors.base05},bg=#${config.lib.stylix.colors.base03}] #I  #W #[fg=#${config.lib.stylix.colors.base03},bg=default] "

      # Remove the default space between windows so our pills sit neatly next to each other
      set-window-option -g window-status-separator ""

      # Make the main status bar background transparent so the pill stands out
      set-option -g status-bg default

      # Create the pill shape for the session name on the right side
      set-option -g status-right "#[fg=#${config.lib.stylix.colors.base0D},bg=default]#[fg=#${config.lib.stylix.colors.base00},bg=#${config.lib.stylix.colors.base0D},bold] 󰀘 #S #[fg=#${config.lib.stylix.colors.base0D},bg=default] "
      
      # Ensure there is enough space to render the text
      set-option -g status-right-length 50

      # Navegación entre paneles estilo Vim
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Abrir nuevas ventanas y splits en el directorio actual
      bind c new-window -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
    ];
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
        not() {
          if [ -z "$NIXOS_SPECIALISATION" ]; then
            nh os test /home/neo/.dotfiles#nixos-btw -- --refresh
          else
            echo "🧪 Testing NixOS Specialisation: $NIXOS_SPECIALISATION..."
            nh os test /home/neo/.dotfiles#nixos-btw -s "$NIXOS_SPECIALISATION" -- --refresh
          fi
        }

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

          local build_success=false
          
          if [ -z "$NIXOS_SPECIALISATION" ]; then
            echo "🔨 Building base NixOS configuration..."
            if nh os switch /home/neo/.dotfiles#nixos-btw -- --refresh; then
              build_success=true
            fi
          else
            echo "🔨 Building NixOS Specialisation: $NIXOS_SPECIALISATION..."
            # Look how much cleaner this is now!
            if nh os switch /home/neo/.dotfiles#nixos-btw -s "$NIXOS_SPECIALISATION" -- --refresh; then
              build_success=true
            fi
          fi

          if [ "$build_success" = true ]; then
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
        nop = "nh clean all --keep 5";
        nv = "nvim";
        better-sops = "sudo SOPS_AGE_KEY=$(sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key) SOPS_EDITOR=${pkgs.neovim}/bin/nvim ${pkgs.sops}/bin/sops";
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
  # --- Phase 5: Cryptographic Identity ---
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

  # Enable the GPG agent and use it for SSH authentication
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # Cache passwords in memory for a short time (e.g., 30 mins)
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
    pinentry = {
      package = pkgs.pinentry-qt;
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
      "--disable-breakpad" # Disables crash reporting to servers
      "--disable-sync" # Disables Google/Brave sync (keep data local)
      "--no-pings"
    ];
    nativeMessagingHosts = [
      (pkgs.writeTextFile {
        name = "keepassxc-brave-manifest";
        text = builtins.toJSON {
          name = "org.keepassxc.keepassxc_browser";
          description = "KeePassXC integration with native messaging support";
          path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
          type = "stdio";
          allowed_origins = [
            "chrome-extension://oboonakemofpalcgghocfoadofidjkkk/"
          ];
        };
        destination = "/etc/chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json";
      })
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
        frame_color = "#61afef";
      };

      urgency_normal = {
        timeout = 5;
      };

      "volume_bar" = {
        stack_tag = "volume";
        summary = "Volume";
        history_ignore = "yes";
        alignment = "center";
      };

    };
  };

  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Open Terminal Here</name>
        <submenu></submenu>
        <unique-id>ghostty-open-here</unique-id>
        <command>ghostty --working-directory="%f"</command>
        <description>Open Ghostty in this directory</description>
        <range></range>
        <patterns>*</patterns>
        <directories/>
      </action>
    </actions>
  '';

systemd.user.services.keepassxc = {
  Unit = {
    Description = "KeePassXC password manager daemon";
    After = [ "graphical-session.target" ];
  };
  Service = {
    # Keep the sleep just in case your compositor takes a moment to settle
    ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
    ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized";
    Restart = "on-failure";
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};

}
