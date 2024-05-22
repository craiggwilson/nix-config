{ lib, config, ... }:
let
  cfg = config.hdwlinux.features.automatic-timezoned;
in
{
  options.hdwlinux.features.automatic-timezoned = {
    enable = lib.hdwlinux.mkBoolOpt true "Whether or not to enable automatic-timezoned.";
  };

  config = lib.mkIf cfg.enable {
    services.automatic-timezoned = {
      enable = true;
    };
  };
}
