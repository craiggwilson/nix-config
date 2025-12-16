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
    enable = lib.hdwlinux.mkEnableOption "upower" config.hdwlinux.services.dbus.enable;
  };

  config = lib.mkIf cfg.enable {
    services.upower.enable = true;
  };
}
