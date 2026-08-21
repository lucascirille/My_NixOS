{ ... }:

{
  # --- KVM / QEMU Support ---
  # services.spice-vdagentd.enable = true; # Dynamic resize & clipboard in virt-manager
  # services.qemuGuest.enable = true;      # Guest integration for KVM/QEMU

  # --- Hyper-V / Universal XRDP Support ---
  virtualisation.hypervGuest.enable = true;
}
