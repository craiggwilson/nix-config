{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.swayidle;
in
{
  options.hdwlinux.features.swayidle = with types; {
    enable = mkEnableOpt ["desktop:hyprland"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; mkIf cfg.enable [
      swayidle
    ];

    xdg.configFile."swayidle/config".text = ''
      timeout 300 'lockscreen'
      timeout 60 'if pgrep -x swaylock; then hyprctl dispatch dpms off; fi' resume 'hyprctl dispatch dpms on'
      lock 'lockscreen'
      before-sleep 'lockscreen'
      after-resume 'hyprctl dispatch dpms on'
    '';
  };
}
