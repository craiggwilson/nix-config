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
    card = lib.hdwlinux.sharedOptions.hardware.graphics.card;
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
