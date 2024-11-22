{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.udisks2;
in
{
  options.hdwlinux.services.udisks2 = {
    enable = lib.mkOption {
      description = "Whether to enable udisks2";
      type = lib.types.bool;
      default = config.hdwlinux.services.dbus.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    services.udisks2.enable = true;
  };
}
