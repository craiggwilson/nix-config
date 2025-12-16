# Flake-parts module for per-system outputs.
# Handles packages and devShells from configured lists.
{
  inputs,
  lib,
  self,
  config,
  ...
}:
{
  perSystem =
    { system, ... }:
    let
      # pkgs for packages - use external overlays only to avoid infinite recursion
      packagesPkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = config.project.external.overlays;
      };

      # pkgs for shells - use full overlays
      shellsPkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };
    in
    {
      # Build packages from the list of paths
      packages =
        let
          packagesConfig = config.project.packages;
          paths = if builtins.isAttrs packagesConfig then packagesConfig.paths else packagesConfig;
        in
        lib.listToAttrs (
          map (path: {
            name = baseNameOf path;
            value = packagesPkgs.callPackage path { };
          }) paths
        );

      # Build dev shells from the list of paths
      devShells = lib.listToAttrs (
        map (path: {
          name = baseNameOf path;
          value =
            let
              shellFn = import path;
              formalArgs = builtins.functionArgs shellFn;
              args =
                (if formalArgs ? pkgs || formalArgs ? "..." then { pkgs = shellsPkgs; } else { })
                // (if formalArgs ? lib || formalArgs ? "..." then { inherit lib; } else { })
                // (if formalArgs ? inputs || formalArgs ? "..." then { inherit inputs; } else { })
                // (if formalArgs ? stdenv || formalArgs ? "..." then { stdenv = shellsPkgs.stdenv; } else { });
            in
            shellFn args;
        }) config.project.shells
      );

      # Formatter
      formatter =
        if config.project.formatter != null then shellsPkgs.${config.project.formatter} else null;
    };
}
