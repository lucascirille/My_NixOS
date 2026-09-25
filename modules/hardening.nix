{
  config,
  pkgs,
  lib,
  username,
  ...
}:

{
  # --- Kernel & Memory Protections ---
  # Use the standard latest kernel or default LTS
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Equivalent kernel command-line hardening parameters
  boot.kernelParams = [
    # Slub/Slab allocator memory poisoning & init on alloc/free
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "slab_nomerge"

    # Restrict debug access and module loading
    "debugfs=off"
    "oops=panic"

    # CPU side-channel & Spectre/Meltdown mitigations
    "spec_store_bypass_disable=on"
    "spectre_v2=on"
    "pti=on"

    # Randomize kernel stack offset on syscall entry
    "randomize_kstack_offset=on"

    # Disable vsyscalls (obsolete interface prone to ROP)
    "vsyscall=none"
  ];

  boot.kernel.sysctl = {
    # Hide kernel pointers and restrict dmesg to root
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;

    # Restrict eBPF to root
    "kernel.unprivileged_bpf_disabled" = 1;

    # Prevent ptracing of non-child processes (useful for securing X11/Qtile memory)
    # "kernel.yama.ptrace_scope" = 2; # Check if you run into issues running apps like Steam
    "kernel.yama.ptrace_scope" = 1; # Good for Anticheats programs


    # TCP Stack Hardening (Spoofing & Floods)
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # Disable ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Filesystem protections (TOCTOU mitigations)
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
  };

  # Blacklist uncommon/obsolete protocols and filesystems
  boot.blacklistedKernelModules = [
    "b43"
    "bcma" # Prevents probe failure logs for unsupported Wi-Fi PHY
    "cramfs"
    "freevxfs"
    "jffs2"
    "hfs"
    "hfsplus"
    "squashfs"
    "udf"
    "dccp"
    "sctp"
    "rds"
    "tipc"
    "firewire-core"
    "thunderbolt"
  ];

  # --- Soporte de Hardware para Llaves Criptográficas (YubiKey/Smartcards) ---
  # services.pcscd.enable = true;

  # --- Access Control & Sudo ---
  security.apparmor = {
    enable = true;
    # Make this on False if you use a Laptop
    # killUnconfinedConfinables = true;
  };

  # Lock down sudo to wheel group with a short timeout
  security.sudo = {
    enable = true;
    execWheelOnly = true;
    extraConfig = ''
      Defaults env_reset, timestamp_timeout=5
      Defaults secure_path="/run/current-system/sw/bin:/run/current-system/sw/sbin"
    '';
  };

  # Disable core dumps to prevent secret leakage from memory
  systemd.coredump.enable = false;

  # --- Networking & Firewall ---
  # Ensure the firewall drops invalid packets
  networking.firewall = {
    enable = true;
    allowPing = false;
    extraCommands = ''
      iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
      ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP
    '';
  };

  # --- Audit Framework ---
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # Set the kernel audit buffer limit to 8192
      "-b 8192"

      "-a exit,always -F arch=b64 -S execve"
      "-w /etc/shadow -p wa -k shadow_access"
      "-w /etc/sudoers -p wa -k sudoers_access"
    ];
  };

  # Use only this when NixOS is used only for fixed machine
  # # Physical peripheral defense against BadUSB
  # services.usbguard = {
  #   enable = true;
  #   dbus.enable = true;
  #   implicitPolicyTarget = "block"; # Block any newly inserted unrecognized devices
  # };

  # System-level Chromium/Brave policies
  # programs.chromium = {
  #   enable = true;
  #   extraOpts = {
  #     "PasswordManagerEnabled" = false;
  #     "AutofillAddressEnabled" = false;
  #     "AutofillCreditCardEnabled" = false;
  #   };
  # };

programs.firejail = {
  enable = true;
  wrappedBinaries = {
    brave = {
      # Points directly to the Home Manager Chromium/Brave package we built above
      executable = "${config.home-manager.users.${username}.programs.chromium.finalPackage}/bin/brave";
      profile = "${pkgs.firejail}/etc/firejail/brave.profile";
      extraArgs = [
        # --- 1. SYSTEM & HARDWARE ACCESS ---
        # Required for NixOS to resolve fonts, Stylix themes, DNS, and SSL certificates
        "--ignore=private-etc" 
        # Required so Brave's internal renderer doesn't crash (needs GPU /dev/dri and RAM mapping)
        "--ignore=private-dev" 
        
        # --- 2. D-BUS FIREWALL ---
        # Re-enables D-Bus (which firejail blocks by default for browsers)
        "--ignore=nodbus"
        # Strict firewall: Only allows Brave to use D-Bus to send desktop notifications.
        # Blocks the browser from snooping on other system services.
        "--dbus-user.talk=org.freedesktop.Notifications"
        
        # --- 3. PROXY EXECUTION BYPASS ---
        # Disables the strict execution block, allowing Brave to run background scripts
        "--ignore=private-bin" 
        # Prevents Firejail's global profile from blacklisting password managers
        "--noblacklist=${pkgs.keepassxc}/bin/keepassxc-proxy"
        
        # --- 4. SOCKET WHITELIST (THE SYMLINK TRAP) ---
        # KeePassXC creates two sockets: a shortcut, and the real socket hidden inside 'app/'.
        # Firejail requires --noblacklist to erase default security blocks 
        
        "--noblacklist=/run/user/1000/app"
        "--noblacklist=/run/user/1000/org.keepassxc.KeePassXC.BrowserServer"


      ];
    };
    # --- MESSAGING ---
    vesktop = {
      executable = "${pkgs.vesktop}/bin/vesktop";
      profile = "${pkgs.firejail}/etc/firejail/vesktop.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };

    # --- MEDIA PLAYERS & STREAMING ---
    mpv = {
      executable = "${pkgs.mpv}/bin/mpv";
      profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
      extraArgs = [ "--ignore=private-etc" "--ignore=private-dev" ];
    };
    spotify = {
      executable = "${pkgs.spotify}/bin/spotify";
      profile = "${pkgs.firejail}/etc/firejail/spotify.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };

    # --- DOCUMENTS & E-BOOKS ---
    zathura = {
      executable = "${pkgs.zathura}/bin/zathura";
      profile = "${pkgs.firejail}/etc/firejail/zathura.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };
    foliate = {
      executable = "${pkgs.foliate}/bin/foliate";
      profile = "${pkgs.firejail}/etc/firejail/foliate.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };
    libreoffice = {
      executable = "${pkgs.libreoffice}/bin/libreoffice";
      profile = "${pkgs.firejail}/etc/firejail/libreoffice.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };

# --- GAMING ---
    steam = {
      executable = "${pkgs.steam}/bin/steam";
      profile = "${pkgs.firejail}/etc/firejail/steam.profile";
      # private-dev MUST be ignored for Steam so it can access your GPU (Vulkan) and game controllers
      extraArgs = [ "--ignore=private-etc" "--ignore=private-dev" ];
    };

    # --- NOTES & ELECTRON APPS ---
    obsidian = {
      executable = "${pkgs.obsidian}/bin/obsidian";
      profile = "${pkgs.firejail}/etc/firejail/obsidian.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };

    # --- IMAGE VIEWERS ---
    nsxiv = {
      executable = "${pkgs.nsxiv}/bin/nsxiv";
      profile = "${pkgs.firejail}/etc/firejail/nsxiv.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };
    feh = {
      executable = "${pkgs.feh}/bin/feh";
      profile = "${pkgs.firejail}/etc/firejail/feh.profile";
      extraArgs = [ "--ignore=private-etc" ];
    };
  };
};

  # --- Privacy (Network Transit) ---

  # Privacidad de Red (MAC Spoofing Inteligente)
  # "stable" crea una MAC única por cada red, evitando el rastreo global
  # pero manteniendo la estabilidad del DHCP local.
  # Verificar si el router perimte esto (puede fallar)
  # networking.networkmanager.wifi.macAddress = "stable";
  # networking.networkmanager.ethernet.macAddress = "stable";

  # DNS-over-TLS (DoT) via systemd-resolved
  # Encrypts all DNS queries so your ISP cannot see which domains you resolve.
  # We use Quad9 (9.9.9.9) as they are heavily privacy-focused and block malware.
  networking.nameservers = [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
  ];
  services.resolved = {
    enable = true;

    settings = {
      Resolve = {
        # "opportinisstic" enctrypts DNS if port 853 is open, but falls back to port 53if the router blocks it.
        DNSOverTLS = "opportunistic";
        # "allow-downgrade" validates DDNSSEC if the network supports it, preventing captive portal deadlocks.
        DNSSEC = "allow-downgrade";
        Domains = [ "~." ];
        FallbackDNS = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };
    };
  };
}
