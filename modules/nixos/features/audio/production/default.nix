{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.audio.production;
in
{
  options.hdwlinux.features.audio.production = {
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
