{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = {
    apps = lib.mkOption {
      description = "List of categorical apps to reference generically.";
      type = lib.types.attrsOf lib.hdwlinux.types.app;
      default = { };
    };

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
          type = lib.hdwlinux.types.tags cfg.tags;
          default = default;
        };
    };
  };
}
