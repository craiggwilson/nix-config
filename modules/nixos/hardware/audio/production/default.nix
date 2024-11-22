{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.hardware.audio.production;
in
{
  options.hdwlinux.hardware.audio.production = {
    enable = lib.mkOption {
      description = "Whether to enable audio production.";
      type = lib.types.bool;
      default = (builtins.elem "audio:production" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.hardware.audio.enable = lib.mkDefault true;

    musnix = {
      enable = true;
      rtcqs.enable = true;
      soundcardPciId = config.hdwlinux.hardware.audio.soundcard.busId;
    };
  };
}
