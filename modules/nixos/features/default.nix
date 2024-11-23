{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features;

in
{
  options.hdwlinux.features = {
    tags = lib.mkOption {
      description = "Tags used to identify feature enablement.";
      type = lib.hdwlinux.tags;
      default = [ ];
    };
    #tags = lib.hdwlinux.mkOpt (lib.types.listOf lib.types.str) [ ] "The tags for features enablement.";
  };

  config = {
    home-manager.sharedModules = [ { hdwlinux.features.tags = cfg.tags; } ];
  };
}
