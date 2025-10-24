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
    enable = lib.hdwlinux.mkEnableOption "dbus" true;
  };

  config = lib.mkIf cfg.enable {
    services.dbus = {
      enable = true;
      implementation = "broker";
    };
  };
}
