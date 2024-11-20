{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.musnix;
in
{
  options.hdwlinux.features.musnix = {
    enable = lib.hdwlinux.mkEnableOpt [ "audio:production" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    musnix = {
      enable = true;
      rtcqs.enable = true;
      soundcardPciId = config.hdwlinux.audio.soundcard.busId;
    };
  };
}
