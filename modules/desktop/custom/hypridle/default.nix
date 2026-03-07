{
  config.substrate.modules.desktop.custom.hypridle = {
    tags = [ "desktop:custom" ];

    homeManager =
      { config, lib, pkgs, ... }:
      {
        home.packages = [ pkgs.hypridle ];

        services.hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = "hyprctl dispatch dpms on || niri msg action power-on-monitors";
            };

            listener = [
              {
                timeout = 240;
                on-timeout = "brightnessctl -s set 10";
                on-resume = "brightnessctl -r";
              }
              {
                timeout = 240;
                on-timeout = "if pgrep -x hyprlock; then hyprctl dispatch dpms off || niri msg action power-off-monitors; fi";
                on-resume = "hyprctl dispatch dpms on || niri msg action power-on-monitors";
              }
              {
                timeout = 300;
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 360;
                on-timeout = "hyprctl dispatch dpms off || niri msg action power-off-monitors";
                on-resume = "hyprctl dispatch dpms on || niri msg action power-on-monitors";
              }
              {
                timeout = 1800;
                on-timeout = "systemctl suspend";
              }
            ];
          };
        };
      };
  };
}

