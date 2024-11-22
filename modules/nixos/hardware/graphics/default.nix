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
    enable = lib.hdwlinux.mkEnableOpt [ "video" ] config.hdwlinux.features.tags;
    card = lib.mkOption {
      description = "The default video card information.";
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
