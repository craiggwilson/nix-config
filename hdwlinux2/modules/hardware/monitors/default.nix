{ lib, ... }:
let
  monitorType = lib.types.submodule {
    options = {
      model = lib.mkOption { type = lib.types.str; };
      serial = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      vendor = lib.mkOption { type = lib.types.str; };
      mode = lib.mkOption { type = lib.types.str; };
      scale = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
      };
      adaptive_sync = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      displaylink = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  monitorsOption = {
    options.hdwlinux.hardware.monitors = lib.mkOption {
      description = "Monitor configurations that can be referenced by name.";
      type = lib.types.attrsOf monitorType;
      default = { };
    };
  };
in
{
  config.substrate.types.monitor = monitorType;

  config.substrate.modules.hardware.monitors-options = {
    nixos = monitorsOption;
    homeManager = monitorsOption;
  };
}
