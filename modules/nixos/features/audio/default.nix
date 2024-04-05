{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.audio; 
in {
  options.hdwlinux.features.audio = with types; {
    enable = mkEnableOpt ["audio"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;
    hardware.pulseaudio.enable = mkForce false;

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

    musnix = {
      enable = true;
      soundcardPciId = "00:1f.3";
    };
  };
}
