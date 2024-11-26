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
    hardware = {
      audio.soundcard = lib.mkOption {
        description = "The soundcard information.";
        type = lib.hdwlinux.types.pcicard;
      };
      graphics = {
        card = lib.mkOption {
          description = "The intel video card information.";
          type = lib.hdwlinux.types.pcicard;
        };
        nvidia.card = lib.mkOption {
          description = "The nvidia graphics card information.";
          type = lib.hdwlinux.types.pcicard;
        };
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
    tags = lib.mkOption {
      description = "Tags used to identify feature enablement.";
      type = lib.hdwlinux.types.allTags;
      default = [ ];
    };
  };

  config = {
    lib.hdwlinux = {
      mkEnableOption =
        name: default:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.types.bool;
          default =
            if builtins.isBool default then
              default
            else if builtins.isString default then
              lib.hdwlinux.elemPrefix default cfg.tags
            else if builtins.isList default then
              lib.hdwlinux.matchTags default cfg.tags
            else
              throw "Only bool, string, or list of strings are supported";
        };
    };

    # lib.hdwlinux = {
    #   mkEnableOption2 =
    #     name: default:
    #     lib.mkOption {
    #       description = "Whether to enable ${name}";
    #       type = lib.hdwlinux.enable cfg.tags;
    #       default = default;
    #       #     if builtins.isBool arg then
    #       #       arg
    #       #     else if builtins.isString arg then
    #       #       lib.hdwlinux.elemPrefix arg cfg.tags
    #       #     else if builtins.isList arg then
    #       #       lib.hdwlinux.matchTags arg cfg.tags
    #       #     else
    #       #       throw "Only bool, string, or list of strings are supported";
    #     };
    # };
  };
}
