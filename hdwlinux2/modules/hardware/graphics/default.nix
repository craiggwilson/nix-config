{ config, lib, ... }:
let
  pcicardType = config.substrate.types.pcicard;

  graphicsCardOption = {
    options.hdwlinux.hardware.graphics.card = lib.mkOption {
      description = "The graphics card information.";
      type = pcicardType;
    };
  };
in
{
  config.substrate.modules.hardware.graphics-options = {
    tags = [ ];
    nixos = graphicsCardOption;
    homeManager = graphicsCardOption;
  };

  config.substrate.modules.hardware.graphics = {
    tags = [ "graphics" ];
    nixos = {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}

