{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.hardware.audio;
in
{
  options.hdwlinux.hardware.audio = {
    enable = config.lib.hdwlinux.mkEnableOption "audio" "audio";
    soundcard = lib.mkOption {
      description = "The soundcard information.";
      type = lib.hdwlinux.types.pcicard;
    };
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;

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

    services.pulseaudio.enable = lib.mkForce false;

    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.hardware.audio.soundcard = cfg.soundcard;
      }
    ];
  };
}
