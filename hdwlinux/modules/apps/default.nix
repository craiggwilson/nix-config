{ lib, ... }:
let
  appType = lib.types.submodule {
    options = {
      package = lib.mkOption {
        description = "The app's package.";
        type = lib.types.package;
      };
      program = lib.mkOption {
        description = "The program name to invoke. If null, uses mainProgram from the package.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      argGroups = lib.mkOption {
        description = "Pre-packaged argument groups.";
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
      };
      desktopName = lib.mkOption {
        description = "The name of the .desktop file for file associations.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };

  appsOption = {
    options.hdwlinux.apps = lib.mkOption {
      description = "Categorical apps to reference generically.";
      type = lib.types.attrsOf appType;
      default = { };
    };
  };
in
{
  # Register the app type in substrate.types
  config.substrate.types.app = appType;

  config.substrate.modules.apps = {
    nixos = appsOption;
    homeManager = appsOption;
  };
}
