{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services.dbus;
in
{
  options.hdwlinux.services.dbus = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable dbus feature.";
  };

  config = lib.mkIf cfg.enable {
    services.dbus = {
      enable = true;
      implementation = "broker";
    };
  };
}
