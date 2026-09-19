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
  # Askpass
  nixos-askpass = pkgs.writeShellScriptBin "nixos-askpass" ''
    ${pkgs.libnotify}/bin/notify-send "NixOS Build" "🔐 Password required to start NixOS Build." -u normal -t 5000
    ${pkgs.rofi}/bin/rofi -dmenu -password -p "🔐 Sudo Password" -theme-str ' mainbox {children: [inputbar];}'
  '';

# Build & Commit (nos)
  nos-script = pkgs.writeShellScriptBin "nos" ''
    export SUDO_ASKPASS="${nixos-askpass}/bin/nixos-askpass"

    # Capture the first argument. If empty, auto-detect the current hostname!
    TARGET_CONFIG=$1
    if [ -z "$TARGET_CONFIG" ]; then
      TARGET_CONFIG=$(hostname)
    fi

    cd ~/.dotfiles || exit 1

    echo "📥 Fetching and integrating remote changes..."
    if ! git pull --rebase --autostash origin main; then
      echo "❌ Git pull failed! Please resolve merge conflicts before building."
      ${pkgs.libnotify}/bin/notify-send "NixOS Build" "❌ Git pull failed!" -u critical -t 10000
      exit 1
    fi

    git add .

    echo "🔐 Authenticating..."
    if ! sudo -A -v 2>/dev/null; then
      echo "❌ Authentication failed!"
      ${pkgs.libnotify}/bin/notify-send "NixOS Build" "❌ Authentication failed!" -u critical -t 10000
      exit 1
    fi

    build_success=false
    
    if [ -z "$NIXOS_SPECIALISATION" ]; then
      echo "🔨 Building NixOS configuration: $TARGET_CONFIG..."
      if nh os switch /home/neo/.dotfiles#"$TARGET_CONFIG" -- --refresh; then
        build_success=true
      fi
    else
      echo "🔨 Building NixOS Specialisation: $NIXOS_SPECIALISATION for $TARGET_CONFIG..."
      if nh os switch /home/neo/.dotfiles#"$TARGET_CONFIG" -s "$NIXOS_SPECIALISATION" -- --refresh; then
        build_success=true
      fi
    fi

    if [ "$build_success" = true ]; then
      echo "✅ Build successful!"
      ${pkgs.libnotify}/bin/notify-send "NixOS Build" "✅ Build successful! System updated." -u normal -t 10000

      if ! git diff-index --quiet HEAD --; then
        echo "📦 Committing and pushing working configuration to Git..."
        git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
        git push
      else
        echo "🧹 Working tree clean. Nothing to commit."
      fi
    else
      echo "❌ Rebuild failed! Aborting Git commit and push."
      ${pkgs.libnotify}/bin/notify-send "NixOS Build" "❌ Build failed! Check terminal for errors." -u critical -t 15000
      exit 1
    fi
  '';

  # Test Configuration (not)
  not-script = pkgs.writeShellScriptBin "not" ''
    # Capture the first argument. If empty, auto-detect the current hostname!
    TARGET_CONFIG=$1
    if [ -z "$TARGET_CONFIG" ]; then
      TARGET_CONFIG=$(hostname)
    fi

    if [ -z "$NIXOS_SPECIALISATION" ]; then
      echo "🧪 Testing NixOS configuration: $TARGET_CONFIG..."
      nh os test /home/neo/.dotfiles#"$TARGET_CONFIG" -- --refresh
    else
      echo "🧪 Testing NixOS Specialisation: $NIXOS_SPECIALISATION for $TARGET_CONFIG..."
      nh os test /home/neo/.dotfiles#"$TARGET_CONFIG" -s "$NIXOS_SPECIALISATION" -- --refresh
    fi
  '';


changeThemeScript = pkgs.writeShellScriptBin "change-theme" ''
    # Prevent globbing error if no images exist
    shopt -s nullglob

    # FIXED: Use a Bash function to handle quoted spaces correctly
    send_notification() {
        ${pkgs.libnotify}/bin/notify-send -a "Theme Switcher" -h string:x-canonical-private-synchronous:theme-progress "$@"
    }
    
    WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"

    # 1. Open GUI (Grid mode). 
    # REMEMBER: Arrows to navigate -> 'm' to mark -> 'q' to quit and apply
    PREVIEWS=$(${pkgs.nsxiv}/bin/nsxiv -t -o "$WORKSHOP_DIR"/*/*.{jpg,png,gif})

    # Exit silently if nothing was marked or selected
    if [ -z "$PREVIEWS" ]; then
        exit 0
    fi

    # 2. Get only the first marked image
    PREVIEW_SELECTED=$(echo "$PREVIEWS" | head -n 1)

    # 3. Extract IDs
    WALLPAPER_DIR=$(dirname "$PREVIEW_SELECTED")
    WALLPAPER_ID=$(basename "$WALLPAPER_DIR")

    IMAGE_PATH="$HOME/.dotfiles/home/assets/wallpapers/current.jpg"
    TEXT_PATH="$HOME/.dotfiles/home/assets/wallpaper-id.txt"

    echo "Generating new color palette for Stylix..."
    
    # 🌟 PROGRESS: 20%
    send_notification -i "$PREVIEW_SELECTED" "Theme Update" "Processing image..." -h int:value:20

    # Process image with ffmpeg
    if ! ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$PREVIEW_SELECTED" -frames:v 1 "$IMAGE_PATH" -hide_banner -loglevel error; then
        send_notification -u critical -i "$PREVIEW_SELECTED" "Theme Error" "Failed to process image!"
        exit 1
    fi
    
    # Save the new ID
    echo -n "$WALLPAPER_ID" > "$TEXT_PATH"

    echo "Running system rebuild (nos)..."
    
    # 🌟 PROGRESS: 50%
    send_notification -i "$IMAGE_PATH" "Theme Update" "Running system rebuild..." -h int:value:50
    
    # Run the nos script
    if ! ${nos-script}/bin/nos; then
        echo "Rebuild failed, aborting theme application."
        send_notification -u critical -i "$IMAGE_PATH" "Theme Error" "Rebuild failed. Aborting."
        exit 1
    fi

    echo "Applying background update..."
    
    # 🌟 PROGRESS: 80%
    send_notification -i "$IMAGE_PATH" "Theme Update" "Restarting wallpaper engine..." -h int:value:80
    
    # ---------------------------------------------------------
    # NEW AUDIO FIX: Aggressively kill ghost processes
    # ---------------------------------------------------------
    systemctl --user stop linux-wallpaperengine.service
    
    # Force kill any lingering instances to prevent audio overlap
    killall -9 linux-wallpaperengine 2>/dev/null || true
    killall -9 mpv 2>/dev/null || true
    
    # Clear the lockout and start fresh
    systemctl --user reset-failed linux-wallpaperengine.service
    systemctl --user start linux-wallpaperengine.service
    # ---------------------------------------------------------

    echo "Theme applied successfully!"
    
    # 🌟 PROGRESS: 100%
    send_notification -i "$IMAGE_PATH" "Theme Update" "Theme fully applied!" -h int:value:100
'';
omnirouteConfig = pkgs.writeText "omniroute-config.json" ''
    {
      "combos": {
        "gemini-2.5-flash": {
          "strategy": "fallback",
          "models": [
            "in-ai/gemini-2.5-flash",
            "t3chat/gemini-2.5-flash",
            "cinf/gemini-2.5-flash",
            "gemini/gemini-2.5-flash"
          ]
        }
      }
    }
  '';
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
    SUDO_ASKPASS = "${config.home.homeDirectory}/.local/bin/nixos-askpass";
  };


  home.packages = with pkgs; [

    cabextract
    
    gcalcli

    changeThemeScript
    
    love

    nixos-askpass
    nos-script
    not-script

    qalculate-gtk


    libreoffice

    rofi
    rofimoji

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

    linux-wallpaperengine

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

  stylix.targets.rofi.enable = false;
  stylix.targets.feh.enable = false;

  programs.keepassxc.enable = true;

xdg.configFile."stylix/colors.json".text = builtins.toJSON {
  base00 = config.lib.stylix.colors.withHashtag.base00; # Default Background
  base01 = config.lib.stylix.colors.withHashtag.base01; # Lighter Background (Status bar, etc)
  base02 = config.lib.stylix.colors.withHashtag.base02; # Selection Background
  base03 = config.lib.stylix.colors.withHashtag.base03; # Comments, Invisibles
  base04 = config.lib.stylix.colors.withHashtag.base04; # Dark Foreground
  base05 = config.lib.stylix.colors.withHashtag.base05; # Default Foreground
  base06 = config.lib.stylix.colors.withHashtag.base06; # Light Foreground
  base07 = config.lib.stylix.colors.withHashtag.base07; # Light Background
  base08 = config.lib.stylix.colors.withHashtag.base08; # Variables, XML Tags, Markup Red (Critical)
  base09 = config.lib.stylix.colors.withHashtag.base09; # Integers, Boolean, Constants, Orange
  base0A = config.lib.stylix.colors.withHashtag.base0A; # Classes, Search Text, Yellow (Warning)
  base0B = config.lib.stylix.colors.withHashtag.base0B; # Strings, Inherited Class, Green (Ok)
  base0C = config.lib.stylix.colors.withHashtag.base0C; # Support, Regular Expressions, Cyan
  base0D = config.lib.stylix.colors.withHashtag.base0D; # Functions, Methods, Accent Blue
  base0E = config.lib.stylix.colors.withHashtag.base0E; # Keywords, Storage, Magenta
  base0F = config.lib.stylix.colors.withHashtag.base0F; # Deprecated, Brown/Other
  image  = config.stylix.image;
};

  # Export Stylix colors to a Rofi-readable file
  xdg.configFile."rofi/colors.rasi".text = ''
    * {
      bg: #${config.lib.stylix.colors.base00};
      bg-alt: #${config.lib.stylix.colors.base01};
      fg: #${config.lib.stylix.colors.base05};
      accent: #${config.lib.stylix.colors.base0D};
      urgent: #${config.lib.stylix.colors.base08};
    }
  '';

programs.ssh = {
    enable = true;
    
    # This silences the warning about default values being removed in the future
    enableDefaultConfig = false; 

    settings = {
      # This manually adds back the standard default that Home Manager used to provide
      "*" = {
        SendEnv = "LANG LC_*";
      };
      
      # Your GitHub configuration using the new upstream directive names
      "github.com" = {
        HostName = "ssh.github.com";
        # Change the port to 443 for GitHub SSH over HTTPS
        Port = 443;
        User = "git";
        # Using the new AddressFamily directive to force IPv4, as GitHub's SSH over HTTPS works better with IPv4
        AddressFamily = "inet";
      };
    };
  };

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
    '';

    mcpServers = {
      "filesystem" = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/neo" ];
      };
    };
    
    settings = {
      model = {
        default = "gemini-2.5-flash";
        provider = "gemini";
        base_url = "http://localhost:20128/v1";
        extra_body = {
          reasoning = { effort = "none"; };
        };
      };
      # fallback_model = {
      #   model = "gemini-2.5-flash";
      #   provider = "gemini";
      #   base_url = "https://generativelanguage.googleapis.com/v1beta";
      # };
      kanban = {
        dispatch_in_gateway = true;
        dispatch_interval_seconds = 10;
      };
      browser = {
        backend = "local";
        headless = false;
      };
      toolsets = [ "all" ];
      computer_use = {
        native_wayland = false;
        permission_mode = "standard";
      };
      
      # Moved inside `settings`
      skills = {
        bundled.enable = true;
        optional = [ "creative/archify" ];
        external_dirs = [
          "${inputs.omniroute-skill}"
          "${inputs.mattpocock-skills}"
          "${inputs.openmontage-skill}"
        ];
      };
    };

    extraPackages = with pkgs; [
      inputs.cua.packages.${pkgs.stdenv.hostPlatform.system}.cua-driver
      uv        
      chromium  
      xdg-utils
      nodejs_22
      xdotool
      xclip
      maim
      ffmpeg
      gnumake
    ];

    environmentFiles = [
      osConfig.sops.secrets."hermes-env".path
    ];
  };

systemd.user.services.omniroute = {
    Unit = {
      Description = "OmniRoute Rootless Podman Container";
      BindsTo = [ "hermes-agent.service" ];
      PartOf = [ "hermes-agent.service" ];
      Before = [ "hermes-agent.service" ];
    };

Service = {
  ExecStartPre = [
    "${pkgs.coreutils}/bin/mkdir -p %h/.local/share/omniroute/data"
    "-${pkgs.podman}/bin/podman rm -f omniroute"
  ];
  
  # Note the new -v ${omnirouteConfig}:/app/data/config.json:ro passed here
ExecStart = "${pkgs.podman}/bin/podman run --name omniroute --rm -p 20128:20128 -v %h/.local/share/omniroute/data:/app/data:U -v ${omnirouteConfig}:/app/data/config.json:ro --env-file ${osConfig.sops.secrets."hermes-env".path} ghcr.io/diegosouzapw/omniroute:latest";
  
  ExecStop = "${pkgs.podman}/bin/podman stop omniroute";
  
  Restart = "on-failure";
  RestartSec = "5s";
};

    Install = {
      WantedBy = [ "hermes-agent.service" ];
    };
  };


    # Configure the Ollama service
  services.ollama = {
    enable = true;
    # This specifically grabs the Vulkan-compiled version instead of ROCm or CPU
    package = pkgs.ollama-vulkan; 
  };

services.linux-wallpaperengine = {
  enable = true;
  wallpapers = [
    {
      monitor = if osConfig.networking.hostName == "laptop" then "eDP-1" else "HDMI-1"; 
      wallpaperId = builtins.readFile ./assets/wallpaper-id.txt; 
      
      # Using the native module options you found!
      audio = {
        processing = false; # Disables audio reactive features (--no-audio-processing)
        automute = false;   # Prevents pipewire sync dropping (--noautomute), if you want to keep audio reactive features make it sure that have the wireplumber.extraConfig:
    #     wireplumber.extraConfig = {
    #   "10-disable-suspend" = {
    #     "monitor.alsa.rules" = [
    #       {
    #         matches = [
    #           { "node.name" = "~alsa_output.*"; }
    #         ];
    #         actions = {
    #           update-props = {
    #             "session.suspend-timeout-seconds" = 0;
    #           };
    #         };
    #       }
    #     ];
    #   };
    # };
      silent = true;      # This completely mutes the wallpaper!
      };
    }
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
  xdg.configFile."rofi/config.rasi".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/config/rofi/config.rasi";


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

    cssSnippets = [
      {
        name = "font-size";
        text = ''
          .markdown-source-view,
          .markdown-preview-view {
            font-size: 18px;
          }
        '';
      }
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

  systemd.user.services.hermes-agent = {
    Service = {
      # Assuming you are on X11 or XWayland. 
      # You can verify your display variable by running `echo $DISPLAY` in your terminal.
      Environment = [ 
        "DISPLAY=:0" 
        # "WAYLAND_DISPLAY=wayland-0" # Uncomment and adjust if using native Wayland later

        # Required for audio and general user session access:
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
    };
  };

systemd.user.services.keepassxc = {
  Unit = {
    Description = "KeePassXC password manager daemon";
    After = [ "graphical-session.target" ];
  };
  Service = {
    # Keep the sleep just in case your compositor takes a moment to settle
    ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
    ExecStart = "${pkgs.keepassxc}/bin/keepassxc --minimized /home/${username}/Passwords.kdbx";
    Restart = "on-failure";
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};

}
