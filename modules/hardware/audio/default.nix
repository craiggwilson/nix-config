{ config, ... }:
let
  pcicardType = config.substrate.types.pcicard;
in
{
  config.substrate.modules.hardware.audio = {
    tags = [ "audio" ];

    generic =
      { lib, ... }:
      {
        options.hdwlinux.hardware.audio.soundcard = lib.mkOption {
          description = "The soundcard information.";
          type = pcicardType lib;
        };
      };

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
