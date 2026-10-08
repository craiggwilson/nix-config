{ ... }:
let
  types = import ../../../lib/types.nix;
in
{
  config.substrate.modules.hardware.graphics = {
    tags = [ "graphics" ];
    generic =
      { lib, ... }:
      {
        options.hdwlinux.hardware.graphics.card = lib.mkOption {
          description = "The graphics card information.";
          type = types.graphicsCard lib;
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
