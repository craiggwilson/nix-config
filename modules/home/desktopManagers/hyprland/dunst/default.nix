{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.dunst;
in
{
  options.hdwlinux.desktopManagers.hyprland.dunst = {
    enable = lib.hdwlinux.mkEnableOption "dunst" false; # config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    services.dunst = {
      enable = true;
      settings = lib.mkIf config.hdwlinux.theme.enable {
        global = {
          frame_color = config.hdwlinux.theme.colors.withHashtag.base0D;
          separator_color = "frame";
        };

        urgency_low = {
          msg_urgency = "low";
          background = config.hdwlinux.theme.colors.withHashtag.base00;
          foreground = config.hdwlinux.theme.colors.withHashtag.base05;
        };

        urgency_normal = {
          msg_urgency = "normal";
          background = config.hdwlinux.theme.colors.withHashtag.base00;
          foreground = config.hdwlinux.theme.colors.withHashtag.base05;
        };

        urgency_critical = {
          msg_urgency = "critical";
          background = config.hdwlinux.theme.colors.withHashtag.base00;
          foreground = config.hdwlinux.theme.colors.withHashtag.base05;
          frame_color = config.hdwlinux.theme.colors.withHashtag.base09;
        };
      };
    };
  };
}
