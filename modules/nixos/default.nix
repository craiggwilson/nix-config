{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.hdwlinux;

  # Extract all monitor names referenced in outputProfiles
  allReferencedMonitors = lib.unique (
    lib.flatten (
      lib.mapAttrsToList (
        _profileName: profile: lib.attrNames profile.outputs
      ) cfg.outputProfiles
    )
  );

  # Get the list of declared monitor names
  declaredMonitors = lib.attrNames cfg.hardware.monitors;

  # Find any monitor references that don't exist in hardware.monitors
  invalidMonitors = lib.filter (m: !(lib.elem m declaredMonitors)) allReferencedMonitors;
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
    assertions = [
      {
        assertion = invalidMonitors == [ ];
        message = ''
          The following monitor names referenced in outputProfiles do not exist in hardware.monitors:
            ${lib.concatStringsSep ", " invalidMonitors}

          Declared monitors: ${lib.concatStringsSep ", " declaredMonitors}
        '';
      }
    ];

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
