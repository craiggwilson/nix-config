_:
let
  types = import ../../../lib/types.nix;
in
{
  config.substrate.modules.hardware.audio = {
    tags = [ "capability:audio" ];

    generic =
      { lib, ... }:
      {
        options.hdwlinux.hardware.audio.soundcard = lib.mkOption {
          description = "The soundcard information.";
          type = types.pcicard lib;
        };
      };

    nixos =
      { lib, pkgs, ... }:
      {
        security.rtkit.enable = true;

        services.pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          audio.enable = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };

        # jack.enable is deprecated: it leaks libjack into every session via a
        # global LD_LIBRARY_PATH. Start JACK clients with `pw-jack <app>` instead.
        environment.systemPackages = [ pkgs.pipewire.jack ];

        services.pulseaudio.enable = lib.mkForce false;
      };
  };
}
