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
    enable = config.lib.hdwlinux.mkEnableOption "audio production" "audio:production";
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
