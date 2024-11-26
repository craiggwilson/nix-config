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
    tags = lib.mkOption {
      description = "Tags used to enable components in the system.";
      type = lib.hdwlinux.types.allTags;
    };
  };

  config = {
    lib.hdwlinux = {
      mkEnableOption =
        name: default:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.hdwlinux.types.tags cfg.tags;
          default = default;
        };
    };

    home-manager.sharedModules = [ { hdwlinux.tags = cfg.tags; } ];
  };
}
