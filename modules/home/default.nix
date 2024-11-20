{
  lib,
  ...
}:
let
  busType = lib.types.strMatching "([0-9a-f]{1,3}[\:][0-9a-f]{1,2}[\.][0-9a-f])?";
  cardType = lib.types.submodule {
    options = {
      vendor = lib.mkOption {
        description = "The graphics card vendor.";
        type = lib.types.enum [
          "intel"
          "nvidia"
        ];
      };
      busId = lib.mkOption {
        description = "The PCI bus id. You can find it using lspci.";
        type = busType;
        example = "00:1f.3";
      };
      path = lib.mkOption {
        description = "The path to the card.";
        type = lib.types.str;
      };
    };
  };
in
{
  options.hdwlinux = {
    audio = lib.mkOption {
      description = "Options to set the audio configuration.";
      type = lib.types.submodule {
        options = {
          soundcardBusId = lib.mkOption {
            description = "The PCI bus id. You can find it using lspci.";
            type = busType;
            example = "00:1f.3";
          };
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
    video = lib.mkOption {
      description = "Options to set the video configuration.";
      type = lib.types.submodule {
        options = {
          discrete = lib.mkOption {
            description = "The discrete video card information.";
            type = cardType;
          };
          integrated = lib.mkOption {
            description = "The integrated video card information.";
            type = cardType;
          };
        };
      };
    };
  };
}
