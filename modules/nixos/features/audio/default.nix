{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.audio;
in
{
  options.hdwlinux.features.audio = {
    enable = lib.hdwlinux.mkEnableOpt [ "audio" ] config.hdwlinux.features.tags;
    soundcardPciId = lib.hdwlinux.mkStrOpt "" "The soundcard PCI identifier. This is passed to musnix";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    hardware.pulseaudio.enable = lib.mkForce false;

    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      audio.enable = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
