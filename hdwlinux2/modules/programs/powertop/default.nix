{
  config.substrate.modules.programs.powertop = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.powertop ];

        powerManagement.powertop = {
          enable = true;
          # Turn off auto suspend for USB HID devices.
          postStart = ''
            HIDDEVICES=$(ls /sys/bus/usb/drivers/usbhid | grep -oE '^[0-9]+-[0-9\.]+' | sort -u)
            for i in $HIDDEVICES; do
              echo -n "Enabling " | cat - /sys/bus/usb/devices/$i/product
              echo 'on' > /sys/bus/usb/devices/$i/power/control
            done
          '';
        };
      };
  };
}
