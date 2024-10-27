{
  lib,
  ...
}:

let
  cardType = lib.types.submodule {
    options = {
      vendor = lib.mkOption {
        description = "The graphics card vendor";
        type = lib.types.enum [
          "intel"
          "nvidia"
        ];
      };
      busId = lib.mkOption {
        description = "The PCI bus id";
        type = lib.types.str;
      };
      path = lib.mkOption {
        description = "The path to the card";
        type = lib.types.str;
      };
    };
  };
in
{
  options.hdwlinux.features.video = {
    integrated = lib.mkOption {
      description = "The integrated video card settings";
      type = cardType;
    };
    discrete = lib.mkOption {
      description = "The discrete video card settings";
      type = cardType;
    };
  };
}
