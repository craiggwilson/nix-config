{ lib, ... }:
{
  options.substrate.settings = {
    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of systems to build for.";
      default = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    };

    finder = lib.mkOption {
      type = lib.types.enum [ "all" ];
      description = "The name of the finder to use.";
      default = "all";
    };

    supportedClasses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "The supported module classes (e.g., nixos, homeManager). Extensions add their classes here.";
      default = [ ];
    };

    extraArgsGenerators = lib.mkOption {
      type = lib.types.listOf (lib.types.functionTo lib.types.attrs);
      description = ''
        Function to compute extra specialArgs for NixOS configurations.
        hostcfg will be null for standalone home-manager and usercfg will be null for nixos.
        Receives: { hostcfg, usercfg, pkgs, inputs }
        Returns: attrset merged into specialArgs
      '';
      default = [ ];
    };
  };

  config.substrate.settings.supportedClasses = [ "nixos" ];
}
