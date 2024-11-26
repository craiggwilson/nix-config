{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware;
in
{
  options.hdwlinux.hardware = {
    monitors = lib.mkOption {
      description = "Options to set the monitor configuration.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            description = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            width = lib.mkOption { type = lib.types.int; };
            height = lib.mkOption { type = lib.types.int; };
            x = lib.mkOption { type = lib.types.int; };
            y = lib.mkOption { type = lib.types.int; };
            scale = lib.mkOption { type = lib.types.int; };
            workspace = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            displaylink = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
        }
      );
    };
  };

  config = {
    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.hardware.monitors = cfg.monitors;
      }
    ];
  };
}
