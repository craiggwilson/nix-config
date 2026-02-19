{ lib, config, ... }:
let
  settings = config.substrate.settings;

  # Extracts a name from a path by taking the basename and removing .nix suffix.
  nameFromPath =
    path:
    let
      basename = baseNameOf path;
    in
    lib.removeSuffix ".nix" basename;

  # Build packages using final (fixed-point pkgs from overlay)
  mkPackages =
    final:
    lib.listToAttrs (
      lib.map (path: {
        name = nameFromPath path;
        value = import path {
          inherit lib;
          pkgs = final;
        };
      }) settings.packages
    );

  mkPackagesDerivationsOnly = final: lib.filterAttrs (_: v: lib.isDerivation v) (mkPackages final);

  namespace = settings.packageNamespace;

  # Overlay that adds packages under the namespace
  packagesOverlay = final: prev: {
    ${namespace} = (prev.${namespace} or { }) // (mkPackages final);
  };
in
{
  options.substrate = {
    settings = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        description = ''
          List of paths to package files.
          Each file should be a function that takes { lib, pkgs, ... } and returns a derivation.
          The package name is derived from the filename (basename without extension).
          Example file: { lib, pkgs, ... }: pkgs.stdenv.mkDerivation { ... }
          Packages are automatically:
          - Exposed as flake packages output
          - Added as an overlay under the packageNamespace
        '';
        default = [ ];
      };

      packageNamespace = lib.mkOption {
        type = lib.types.str;
        description = ''
          The namespace under which packages are exposed in the overlay.
          Example: "hdwlinux" results in pkgs.hdwlinux.<packageName>
        '';
        default = "custom";
      };
    };

    packages = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.attrsOf lib.types.package);
      description = ''
        The packages defined in settings.packages, keyed by system.
        Matches flake packages output format: packages.<system>.<name> = derivation.
        This is populated by the builder (e.g., flake-parts adapter).
      '';
      default = { };
    };
  };

  config.substrate = lib.mkIf (settings.packages != [ ]) {
    lib = {
      inherit mkPackages mkPackagesDerivationsOnly;
    };

    # Add packages overlay to settings.overlays for internal use
    settings.overlays = [ packagesOverlay ];

    outputs = {
      # Expose packages overlay in flake outputs
      overlays = [
        {
          type = "global";
          build =
            { ... }:
            {
              packages = packagesOverlay;
            };
        }
      ];

      # Expose packages as flake output
      packages = [
        {
          type = "per-system";
          build = { pkgs, ... }: mkPackagesDerivationsOnly pkgs;
        }
      ];
    };
  };
}
