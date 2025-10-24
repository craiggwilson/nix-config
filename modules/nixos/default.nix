{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.hdwlinux;

  # Recursively find all default.nix files in subdirectories
  # Only do this when not using snowfall-lib (which auto-imports modules)
  # We detect snowfall-lib by checking if the namespace is already set
  findModules =
    dir:
    let
      entries = builtins.readDir dir;
      subdirs = lib.filterAttrs (name: type: type == "directory") entries;

      # For each subdirectory, check if it has a default.nix
      moduleFiles = lib.mapAttrsToList (
        name: _:
        let
          modulePath = dir + "/${name}/default.nix";
        in
        if builtins.pathExists modulePath then
          [ modulePath ] ++ findModules (dir + "/${name}")
        else
          findModules (dir + "/${name}")
      ) subdirs;
    in
    lib.flatten moduleFiles;

  # Get all module files except this one
  # Only auto-import if we're not using snowfall-lib
  # Snowfall-lib provides lib.snowfall, so we can detect it
  allModules = if (lib ? snowfall) then [ ] else findModules ./.;
in
{
  imports = allModules;

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
