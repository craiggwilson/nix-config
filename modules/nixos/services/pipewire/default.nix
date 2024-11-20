{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services.pipewire;
in
{
  options.hdwlinux.services.pipewire = {
    enable = lib.hdwlinux.mkEnableTagsOpt "pipewire" [ "audio" ] config.hdwlinux.features.tags;
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
