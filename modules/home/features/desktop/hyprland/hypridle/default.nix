{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.hypridle;
in
{
  options.hdwlinux.features.desktop.hyprland.hypridle = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hypridle ];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = 240;
            on-timeout = "pidof hyprlock || brightnessctl -s set 10";
            on-resume = "brightnessctl -r";
          }
          {
            timeout = 240;
            on-timeout = "if pgrep -x hyprlock; then hyprctl dispatch dpms off; fi";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 360;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          # {
          #   timeout = 1800;
          #   on-timeout = "systemctl suspend";
          # }
        ];
      };
    };
  };
}
