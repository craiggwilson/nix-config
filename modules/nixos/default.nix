{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = {
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
    video = lib.mkOption {
      description = "Options to set the video configuration.";
      type = lib.types.submodule {
        options = {
          intel = lib.mkOption {
            description = "The intel video card information.";
            type = lib.hdwlinux.pcicard;
          };
          nvidia = lib.mkOption {
            description = "The nvidia video card information.";
            type = lib.hdwlinux.pcicard;
          };
        };
      };
    };
  };

  config.home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
    {
      hdwlinux.monitors = cfg.monitors;
      hdwlinux.video = cfg.video;
    }
  ];
}
