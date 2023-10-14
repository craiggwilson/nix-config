{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.audio; 
in {
  options.hdwlinux.packages.audio = with types; {
    enable = mkBoolOpt false "Whether or not to enable audio support.";
  };

  config = mkIf cfg.enable {
    sound.enable = true;
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

    hdwlinux.user.extraGroups = [ "audio" ];
  };
}
