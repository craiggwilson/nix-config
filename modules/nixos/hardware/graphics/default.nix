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
    enable = config.lib.hdwlinux.mkEnableOption "graphics" "graphics";
    card = lib.mkOption {
      description = "The default graphics card information.";
      type = lib.hdwlinux.types.pcicard;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.hardware.graphics.card = cfg.card;
      }
    ];
  };
}
