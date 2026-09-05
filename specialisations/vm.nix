{ ... }:

{
  # system.nixos.tags = [ "VM-Profile" ] # if you want to change the name for the boot

  # --- KVM / QEMU Support ---
  # services.spice-vdagentd.enable = true; # Dynamic resize & clipboard in virt-manager
  # services.qemuGuest.enable = true;      # Guest integration for KVM/QEMU

  # --- Hyper-V / Universal XRDP Support ---
  virtualisation.hypervGuest.enable = true;

  services.smartd.enable = false;
}
