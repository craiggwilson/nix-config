{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = {
    inherit (lib.hdwlinux.sharedOptions)
      apps
      flake
      outputProfiles
      tags
      ;
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

    home-manager.sharedModules = [
      {
        hdwlinux = {
          apps = cfg.apps;
          flake = cfg.flake;
          outputProfiles = cfg.outputProfiles;
          tags = cfg.tags;
        };
      }
    ];
  };
}
