{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.upower;
in
{
  options.hdwlinux.services.upower = {
    enable = lib.mkOption {
      description = "Whether to enable upower";
      type = lib.types.bool;
      default = config.hdwlinux.services.dbus.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    services.upower.enable = true;
  };
}
