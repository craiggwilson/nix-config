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
    audio = lib.mkOption {
      description = "Options to set the audio configuration.";
      type = lib.types.submodule {
        options = {
          soundcard = lib.mkOption {
            description = "The soundcard information.";
            type = lib.hdwlinux.pcicard;
          };
        };
      };
    };
    features = {
      tags = lib.mkOption {
        description = "Tags used to identify feature enablement.";
        type = lib.hdwlinux.tags;
        default = [ ];
      };
    };
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

  config = {
    lib.hdwlinux = {
      mkEnableOption =
        name: tag:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.types.bool;
          default = lib.hdwlinux.elemPrefix tag cfg.features.tags;
        };

      mkEnableAllOption =
        name: tags:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.types.bool;
          default = lib.hdwlinux.elemsAll tags cfg.features.tags;
        };

      mkEnableAnyOption =
        name: tags:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.types.bool;
          default = lib.hdwlinux.elemsAll tags cfg.features.tags;
        };
    };
  };
}
