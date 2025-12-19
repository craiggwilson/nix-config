{ lib, config, ... }:
let
  settings = config.substrate.settings;
  namespace = settings.packageNamespace;

  packagesOverlay = final: prev: {
    ${namespace} = (prev.${namespace} or { }) // (config.substrate.lib.mkPackages final);
  };
in
{
  options.substrate = {
    settings.overlays = lib.mkOption {
      type = lib.types.listOf (lib.types.functionTo (lib.types.functionTo lib.types.attrs));
      description = ''
        Additional overlays to apply to nixpkgs when building configurations.
        These are combined with the packages overlay via substrate.lib.mkAllOverlays.
      '';
      default = [ ];
    };

    overlays = lib.mkOption {
      type = lib.types.functionTo (lib.types.functionTo lib.types.attrs);
      description = ''
        The packages overlay that adds substrate packages under the namespace.
        Exposed via flake outputs for external use.
      '';
      readOnly = true;
      default = packagesOverlay;
    };
  };
}

