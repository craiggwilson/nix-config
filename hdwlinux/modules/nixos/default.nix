{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  imports = lib.hdwlinux.findSubdirFilesRecursive { dir = ./.; };

  options.hdwlinux = {
    apps = lib.mkOption {
      description = "List of categorical apps to reference generically.";
      type = lib.types.attrsOf lib.hdwlinux.types.app;
      default = { };
    };

    outputProfiles = lib.mkOption {
      description = "Options to set the output profiles.";
      type = lib.types.attrsOf lib.hdwlinux.types.outputProfile;
    };

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

    home-manager.sharedModules = [
      {
        hdwlinux = {
          apps = cfg.apps;
          outputProfiles = cfg.outputProfiles;
          tags = cfg.tags;
        };
      }
    ];
  };
}
