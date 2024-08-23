{ config, lib, ... }:

let
  cfg = config.hdwlinux.features.automatic-timezoned;
in
{
  options.hdwlinux.features.automatic-timezoned = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable automatic time zone detection";
  };

  config = lib.mkIf cfg.enable {
    services.automatic-timezoned = {
      enable = true;
    };
  };
}
