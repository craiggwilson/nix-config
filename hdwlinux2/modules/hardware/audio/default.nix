{ config, lib, ... }:
let
  pcicardType = config.substrate.types.pcicard;

  soundcardOption = {
    options.hdwlinux.hardware.audio.soundcard = lib.mkOption {
      description = "The soundcard information.";
      type = pcicardType;
    };
  };
in
{
  config.substrate.modules.hardware.audio-options = {
    tags = [ ];
    nixos = soundcardOption;
    homeManager = soundcardOption;
  };

  config.substrate.modules.hardware.audio = {
    tags = [ "audio" ];
    nixos =
      { lib, ... }:
      {
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
      };
  };
}

