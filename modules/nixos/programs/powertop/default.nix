{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.powertop;

in
{
  options.hdwlinux.programs.powertop = {
    enable = lib.hdwlinux.mkEnableOption "powertop" true;
    autotune = lib.mkOption {
      description = "Whether to run powertop --auto-tune at startup.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.powertop ];

    powerManagement.powertop = {
      enable = cfg.autotune;
      postStart = # Turn off auto suspend for USB HID devices.
        ''
          HIDDEVICES=$(ls /sys/bus/usb/drivers/usbhid | grep -oE '^[0-9]+-[0-9\.]+' | sort -u)
          for i in $HIDDEVICES; do
            echo -n "Enabling " | cat - /sys/bus/usb/devices/$i/product
            echo 'on' > /sys/bus/usb/devices/$i/power/control
          done
        '';
    };
  };
}
