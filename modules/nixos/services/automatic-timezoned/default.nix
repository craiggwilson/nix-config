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
    enable = lib.mkOption {
      description = "Whether to enable automatic-timezoned.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.automatic-timezoned = {
      enable = true;
    };
  };
}
