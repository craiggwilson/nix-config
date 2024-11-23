{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.services.kolide;
in
{
  options.hdwlinux.services.kolide = {
    enable = lib.mkOption {
      description = "Whether to enable kolide.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "work" config.hdwlinux.features.tags);
    };
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
