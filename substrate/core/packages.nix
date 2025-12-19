{ lib, ... }:
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
          - Exposed as substrate.packages (flake packages output format)
          - Added as substrate.overlays for use in nixpkgs
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
}

