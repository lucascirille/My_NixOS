{ ... }:

{

  # SMART monitoring (not for VM)
  services.smartd = {
    enable = true;
    defaults.monitored = "-a -o on -S on -n standby,q";

    # Pop-up notifications
    notifications.systembus-notify.enable = true;

    # Print message to any open terminal widows
    notifications.wall.enable = true;

    # Send a test notification on boot
    notifications.test = true;

  };

  virtualisation.libvirtd.enable = true;

}
