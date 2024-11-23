{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = {
    features = {
      tags = lib.mkOption {
        description = "Tags used to identify feature enablement.";
        type = lib.hdwlinux.tags;
        default = [ ];
      };
    };
  };

  config = {
    lib.hdwlinux.features = {
      mkEnableOption =
        name: tag:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.types.bool;
          default = lib.hdwlinux.elemPrefix tag cfg.features.tags;
        };

      mkEnableAllOption =
        name: tags:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.types.bool;
          default = lib.hdwlinux.elemsAll tags cfg.features.tags;
        };
    };

    home-manager.sharedModules = [ { hdwlinux.features.tags = cfg.features.tags; } ];
  };
}
