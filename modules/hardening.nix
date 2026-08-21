{
  config,
  pkgs,
  lib,
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
    "kernel.yama.ptrace_scope" = 2;

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

  # --- Access Control & Sudo ---
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
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

  # Change extraOpts to of if you dont want to store your information
  programs.chromium = {
    enable = true;
    extraOpts = {
      "PasswordManagerEnabled" = true;
      "AutofillAddressEnabled" = true;
      "AutofillCreditCardEnabled" = true;
    };
  };

}
