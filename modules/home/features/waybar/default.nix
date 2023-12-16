{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.waybar;
in
{
  options.hdwlinux.features.waybar = with types; {
    enable = mkEnableOpt ["desktop:hyprland"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    xdg.configFile."waybar/colors.css".text = mkIf config.hdwlinux.theme.enable ''
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
      settings = [{
        layer = "top";
        position = "top";
        mod = "dock";
        exclusive = true;
        passthrough = false;
        gtk-layer-shell = true;
        height = 35;
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "tray"
          "battery"
          "backlight"
          "pulseaudio"
          "pulseaudio#microphone"
        ];
        backlight = {
          format = "{icon} {percent}%";
          format-icons = [ "" "" ];
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
          format-icons = [ " " " " " " " " " " ];
        };

        clock = {
          format = "{: %I:%M   %m/%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
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
            headphone =  "";
            hands-free = "";
            headset =  "";
            phone =  "";
            portable =  "";

            car =  "";
            default =  [ "" "" "" ];
          };
        };

        "pulseaudio#microphone" = {
          format = "{format_source}";
          format-source =" {volume}%";
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
      }];

      style = ''
        @import url("colors.css"); 

        * {
            border: none;
            border-radius: 0;
            font-family: Cartograph CF Nerd Font, monospace;
            font-weight: bold;
            font-size: 14px;
            min-height: 0;
        }

        window#waybar {
            background: rgba(21, 18, 27, .5);
        }

        tooltip {
            background: @base01;
            border-radius: 10px;
            border-width: 2px;
            border-style: solid;
            border-color: @base01;
        }

        #backlight,
        #battery,
        #clock,
        #custom-caffeine,
        #pulseaudio,
        #network,
        #tray,
        #window,
        #workspaces {
            background: @base00;
            padding: 0px 10px;
            margin: 3px 0px;
            border: 1px solid @base01;
        }

        #battery {
            color: @base08;
            border-radius: 10px;
            margin-right: 10px;
        }

        #backlight {
            color: @base0B;
            border-radius: 10px 0px 0px 10px;
            border-right: 0px;
            margin-left: 5px;
        }

        #clock {
            border-radius: 10px;
            margin-left: 5px;
        }

        #pulseaudio {
            color: @base0D;
            border-left: 0px;
            border-right: 0px;
        }

        #pulseaudio.microphone {
            color: @base0E;
            border-radius: 0px 10px 10px 0px;
            border-left: 0px;
            margin-right: 5px;
        }

        #tray {
            border-radius: 10px;
            margin-right: 10px;
        }

        #window {
            border-radius: 10px;
            margin-left: 60px;
            margin-right: 60px;
        }

        #workspaces {
            border-radius: 10px;
            margin-left: 10px;
            padding-right: 0px;
            padding-left: 5px;
        }

        #workspaces button {
            color: @base02;
            padding: 5px;
            margin-right: 5px;
        }

        #workspaces button.active {
            color: @base0E;
        }

        #workspaces button.focused {
            color: @base0E;
            border-radius: 10px;
        }

        #workspaces button.urgent {
            color: @base0E;
            border-radius: 10px;
        }

        #workspaces button:hover {
            color: @base0E;
            border-radius: 10px;
        }
      '';
    };
  };
}
