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
    enable = lib.hdwlinux.mkEnableOption "udisks2" config.hdwlinux.services.dbus.enable;
  };

  config = lib.mkIf cfg.enable {
    services.udisks2.enable = true;
  };
}
