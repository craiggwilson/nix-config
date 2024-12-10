{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.waybar;
in
{
  options.hdwlinux.desktopManagers.hyprland.waybar = {
    enable = lib.hdwlinux.mkEnableOption "waybar" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."waybar/colors.css".text = lib.mkIf config.hdwlinux.theme.enable ''
      @define-color base00 ${config.hdwlinux.theme.colors.withHashtag.base00};
      @define-color base01 ${config.hdwlinux.theme.colors.withHashtag.base01};
      @define-color base02 ${config.hdwlinux.theme.colors.withHashtag.base02};
      @define-color base03 ${config.hdwlinux.theme.colors.withHashtag.base03};
      @define-color base04 ${config.hdwlinux.theme.colors.withHashtag.base04};
      @define-color base05 ${config.hdwlinux.theme.colors.withHashtag.base05};
      @define-color base06 ${config.hdwlinux.theme.colors.withHashtag.base06};
      @define-color base07 ${config.hdwlinux.theme.colors.withHashtag.base07};
      @define-color base08 ${config.hdwlinux.theme.colors.withHashtag.base08};
      @define-color base09 ${config.hdwlinux.theme.colors.withHashtag.base09};
      @define-color base0A ${config.hdwlinux.theme.colors.withHashtag.base0A};
      @define-color base0B ${config.hdwlinux.theme.colors.withHashtag.base0B};
      @define-color base0C ${config.hdwlinux.theme.colors.withHashtag.base0C};
      @define-color base0D ${config.hdwlinux.theme.colors.withHashtag.base0D};
      @define-color base0E ${config.hdwlinux.theme.colors.withHashtag.base0E};
      @define-color base0F ${config.hdwlinux.theme.colors.withHashtag.base0F};
    '';

    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
      style = ./style.css;
      settings = [
        {
          layer = "top";
          position = "top";
          mod = "dock";
          exclusive = true;
          passthrough = false;
          gtk-layer-shell = true;
          height = 35;
          modules-left = [
            "idle_inhibitor"
            "hyprland/workspaces"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "tray"
            "battery"
            "backlight"
            "pulseaudio"
            "pulseaudio#microphone"
          ];
          backlight = {
            format = "{icon} {percent}%";
            format-icons = [
              ""
              ""
            ];
          };
          battery = {
            states = {
              good = 95;
              warning = 30;
              critical = 20;
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = " {capacity}%";
            format-alt = "{time} {icon}";
            format-icons = [
              " "
              " "
              " "
              " "
              " "
            ];
          };

          clock = {
            format = " {:%I:%M   %m/%d}";
            tooltip-format = ''
              <big>{:%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            tooltip = false;
            format-muted = " Muted";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            on-click-right = "pavucontrol -t 3";
            on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1";
            on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            scroll-step = 5;
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";

              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
          };

          "pulseaudio#microphone" = {
            format = "{format_source}";
            format-source = " {volume}%";
            format-source-muted = " Muted";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            on-click-right = "pavucontrol -t 4";
            on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ --limit 1";
            on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-";
            scroll-step = 5;
          };

          tray = {
            icon-size = 13;
            spacing = 13;
          };
        }
      ];
    };
  };
}
