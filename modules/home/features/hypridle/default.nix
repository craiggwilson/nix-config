{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.hypridle;
in
{
  options.hdwlinux.features.hypridle = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hypridle ];

    xdg.configFile."hypr/hypridle.conf".text = ''
      general {
        lock_cmd = pidof swaylock || swaylock -f          
        before_sleep_cmd = loginctl lock-session   
        after_sleep_cmd = hyprctl dispatch dpms on 
      }

      listener {
        timeout = 240                          
        on-timeout = pidof swaylock || brightnessctl -s set 10
        on-resume = brightnessctl -r
      }

      listener {
        timeout = 240                          
        on-timeout = if pgrep -x swaylock; then hyprctl dispatch dpms off; fi
        on-resume = hyprctl dispatch dpms on
      }

      listener {
        timeout = 300                            
        on-timeout = loginctl lock-session
      }

      listener {
        timeout = 360                          
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
      }

      #listener {
      #  timeout = 1800                                # 30min
      #  on-timeout = systemctl suspend                # suspend pc
      #}
    '';
  };
}
