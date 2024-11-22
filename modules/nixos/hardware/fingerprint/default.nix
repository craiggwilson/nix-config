{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.hardware.fingerprint;
  laptop-lid = pkgs.writeShellScript "laptop-lid" ''
    lock=$XDG_STATE_HOME/.fingerprint-reader-disabled

    # match for either display port or hdmi port
    if grep -Fq closed /proc/acpi/button/lid/LID0/state
    then
      touch "$lock"
      echo 0 > /sys/bus/usb/devices/${cfg.laptop-lid}/authorized
    elif [ -f "$lock" ]
    then
      echo 1 > /sys/bus/usb/devices/${cfg.laptop-lid}/authorized
      rm "$lock"
    fi
  '';
in
{
  options.hdwlinux.hardware.fingerprint = {
    enable = lib.hdwlinux.mkEnableOpt [ "fingerprint" ] config.hdwlinux.features.tags;
    laptop-lid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config =
    lib.mkIf cfg.enable {
      services.fprintd.enable = true;
    }
    // lib.mkIf (cfg.enable && cfg.laptop-lid != null) {
      # disable when the lid is closed.
      services.acpid = {
        enable = true;
        lidEventCommands = "${laptop-lid}";
      };

      systemd.services.fingerprint-laptop-lid = {
        enable = true;
        description = "Disable fingerprint reader when laptop lid closes";
        serviceConfig = {
          ExecStart = laptop-lid;
        };
        wantedBy = [
          "multi-user.target"
          "suspend.target"
        ];
        after = [ "suspend.target" ];
      };
    };
}
