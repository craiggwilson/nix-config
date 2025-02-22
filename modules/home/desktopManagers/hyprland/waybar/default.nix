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

    systemd.user.services.waybar.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";

    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
      };
      style = ./style.css;
      settings = [
        {
          layer = "top";
          margin = "4 8";
          position = "top";
          exclusive = true;
          passthrough = false;
          gtk-layer-shell = true;
          height = 35;
          reload_style_on_change = true;
          modules-left = [
            "idle_inhibitor"
            "hyprland/workspaces"
            "mpris"
          ];
          modules-center = [
            "clock"
            "systemd-failed-units"
          ];
          modules-right = [
            "tray"
            "group/network"
            "group/stats"
            "backlight"
            "group/sound"
            "custom/notifications"
            "custom/recording"
          ];

          "group/network" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 500;
              transition-left-to-right = false;
            };
            modules = [
              "network"
              "network#speed"
            ];
          };

          "group/sound" = {
            orientation = "inherit";
            modules = [
              "cava"
              "pulseaudio"
              "pulseaudio#microphone"
            ];
          };

          "group/stats" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 500;
              transition-left-to-right = false;
            };
            modules = [
              "battery"
              "cpu"
              "memory"
              "temperature"
            ];
          };

          backlight = {
            format = "{icon} {percent}%";
            format-icons = [
              "󰃞"
              "󰃟"
              "󰃠"
            ];
            on-scroll-down = "screenctl backlight lower";
            on-scroll-up = "screenctl backlight raise";
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

          cava = {
            method = "pipewire";
            bars = 12;
            bar_delimiter = 0;
            sleep_timer = 5;
            hide_on_silence = true;
            waves = true;
            format-icons = [
              "▁"
              "▂"
              "▃"
              "▄"
              "▅"
              "▆"
              "▇"
              "█"
            ];
          };

          clock = {
            format = " {:%I:%M   %m/%d}";
            tooltip-format = ''
              <big>{:%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
          };

          cpu = {
            interval = 5;
            format = "{icon} CPU: {usage}%";
            format-icons = [
              "󰝦"
              "󰪞"
              "󰪟"
              "󰪠"
              "󰪡"
              "󰪢"
              "󰪣"
              "󰪤"
              "󰪥"
            ];
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          memory = {
            interval = 5;
            format = "{icon} MEM: {percentage}%";
            format-icons = [
              "󰝦"
              "󰪞"
              "󰪟"
              "󰪠"
              "󰪡"
              "󰪢"
              "󰪣"
              "󰪤"
              "󰪥"
            ];
          };

          mpris = {
            format = "{status_icon} {artist}: {title}";
            tooltip-format = "{album}";
            status-icons = {
              playing = "🎵";
              paused = "⏸";
            };
            artist-len = 20;
            title-len = 50;
          };

          network = {
            format-wifi = "{icon} {essid}";
            format-icons = [
              "󰤟"
              "󰤢"
              "󰤥"
            ];
            format-ethernet = "󰈀";
            format-disconnected = "Disconnected";
            tooltip-format = "{ifname} {ipaddr}/{cidr}";
            on-click = "appctl exec networkmenu";
          };

          "network#speed" = {
            format = " {bandwidthUpBits}  {bandwidthDownBits}";
            tooltip-format = " {bandwidthUpBytes}  {bandwidthDownBytes}";
            interval = 1;
            on-click = "appctl exec-known terminal bandwhich";
          };

          "custom/notifications" = {
            exec = "notifyctl watch";
            return-type = "json";
            format = "{}";
            on-click = "notifyctl toggle-tag do-not-disturb";
            on-click-right = "notifyctl dismiss-all";
            restart-interval = 1;
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            tooltip = false;
            format-muted = " Muted";
            on-click = "audioctl output mute toggle";
            on-click-middle = "appctl exec easyeffects";
            on-click-right = "appctl exec audioctl output show-menu";
            on-scroll-up = "audioctl output volume raise";
            on-scroll-down = "audioctl output volume lower";
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
            on-click = "audioctl input mute toggle";
            on-click-middle = "appctl exec easyeffects";
            on-click-right = "appctl exec audioctl input show-menu";
            on-scroll-up = "audioctl input volume raise";
            on-scroll-down = "audioctl input volume lower";
            scroll-step = 5;
          };

          "custom/recording" = {
            exec = "screenctl record watch";
            hide-empty-text = true;
            format = "{}";
            on-click = "screenctl record stop";
            restart-interval = 1;
          };

          systemd-failed-units = {
            on-click = "appctl exec-known terminal launch systemctl --failed && systemctl --user --failed";
          };

          temperature = {
            format = " {temperatureF}°F";
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
