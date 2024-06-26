{ config, lib, ... }:
let
  cfg = config.hdwlinux.features.kolide;
in
{
  options.hdwlinux.features.kolide = {
    enable = lib.hdwlinux.mkEnableOpt [ "work" ] config.hdwlinux.features.tags;
    enrollmentSecret = lib.mkOption {
      type = lib.types.str;
      description = "The enrollment secret for the sensor";
    };
  };

  config = lib.mkIf cfg.enable {
    services.kolide-launcher.enable = true;

    environment.etc."kolide-k2/secret" = {
      mode = "0600";
      text = cfg.enrollmentSecret;
    };
  };
}
