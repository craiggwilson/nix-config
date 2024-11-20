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
    enable = lib.hdwlinux.mkBoolOpt true "Wheter to enable automatic-timezoned.";
  };

  config = lib.mkIf cfg.enable {
    services.automatic-timezoned = {
      enable = true;
    };
  };
}
