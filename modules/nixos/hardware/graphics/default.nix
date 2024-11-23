{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware.graphics;
in
{
  options.hdwlinux.hardware.graphics = {
    enable = lib.mkOption {
      description = "Whether to enable graphics.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "video" config.hdwlinux.features.tags);
    };
    card = lib.mkOption {
      description = "The default graphics card information.";
      type = lib.hdwlinux.pcicard;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.video.intel = cfg.card;
      }
    ];
  };
}
