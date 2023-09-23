{ config, pkgs, lib, ...}: {
  sound.enable = true;

  hardware.pulseaudio.enable = false; # enable with pipewire

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

  security.rtkit.enable = true;
}
