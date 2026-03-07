{ config, ... }:
let
  pcicardType = config.substrate.types.pcicard;
in
{
  config.substrate.modules.hardware.graphics = {
    tags = [ "graphics" ];
    generic =
      { lib, ... }:
      {
        options.hdwlinux.hardware.graphics.card = lib.mkOption {
          description = "The graphics card information.";
          type = pcicardType lib;
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
