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
    enable = lib.mkOption {
      description = "Whether to enable dbus.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.dbus = {
      enable = true;
      implementation = "broker";
    };
  };
}
