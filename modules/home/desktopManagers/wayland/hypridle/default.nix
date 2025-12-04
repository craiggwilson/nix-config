{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.hypridle;
in
{
  options.hdwlinux.desktopManagers.wayland.hypridle = {
    enable = lib.hdwlinux.mkEnableOption "hypridle" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hypridle ];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "screenctl power on";
        };

        listener = [
          {
            timeout = 240;
            on-timeout = "pidof hyprlock || screenctl backlight set 10";
            on-resume = "screenctl backlight restore";
          }
          {
            timeout = 240;
            on-timeout = "if pgrep -x hyprlock; then screenctl power off; fi";
            on-resume = "screenctl power on";
          }
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 360;
            on-timeout = "screenctl power off";
            on-resume = "screenctl power on";
          }
          {
            timeout = 1800;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
