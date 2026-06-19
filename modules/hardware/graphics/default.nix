{ config, ... }:
let
  graphicsCardTyper = config.substrate.types.graphicsCard;
in
{
  config.substrate.modules.hardware.graphics = {
    tags = [ "graphics" ];
    generic =
      { lib, ... }:
      {
        options.hdwlinux.hardware.graphics.card = lib.mkOption {
          description = "The graphics card information.";
          type = graphicsCardTyper lib;
        };
      };
    nixos = {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}
