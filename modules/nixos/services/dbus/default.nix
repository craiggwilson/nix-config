{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.dbus;
in
{
  options.hdwlinux.features.dbus = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable dbus feature.";
  };

  config = lib.mkIf cfg.enable {
    services.dbus.implementation = "broker";
  };
}
