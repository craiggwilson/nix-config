{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.automatic-timezoned;
in
{

  options.hdwlinux.services.automatic-timezoned = {
    enable = lib.hdwlinux.mkEnableOption "automatic-timezoned" true;
  };

  config = lib.mkIf cfg.enable {
    services.automatic-timezoned = {
      enable = true;
    };
  };
}
