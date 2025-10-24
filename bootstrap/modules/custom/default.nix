{ lib, ... }:
{
  options.custom = {
    libs = lib.mkOption {
      description = "Custom libraries to load.";
      type = lib.types.listOf lib.types.raw;
      default = [ ];
    };

    overlays = lib.mkOption {
      description = "A list of overlays to apply to the nixpkgs instance.";
      type = lib.types.listOf lib.types.raw;
      default = [ ];
    };

    packages = lib.mkOption {
      description = "A list of packages.";
      default = [ ];
      type = lib.types.listOf lib.types.raw;
    };
  };
}
