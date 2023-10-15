{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.waybar;
  pamixer = "${getBin pkgs.pamixer}/bin/pamixer";
  pavucontrol = "${getBin pkgs.pavucontrol}/bin/pavucontrol";
in
{
  options.hdwlinux.packages.waybar = with types; {
    enable = mkBoolOpt false "Whether or not to enable waybar.";
  };

  #TODO: finish colors here...

  config = mkIf cfg.enable {
    hdwlinux.home.programs.waybar = {
      enable = true;
      settings = [{
        layer = "top";
        position = "top";
        mod = "dock";
        exclusive = true;
        passthrough = false;
        gtk-layer-shell = true;
        height = 32;
        modules-left = [
          "clock"
          "hyprland/workspaces"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          "tray"
          "battery"
          "backlight"
          "pulseaudio"
          "pulseaudio#microphone"
        ];
        "hyprland/window" = {
          format = "{}";
          separate-outputs = true;
        };
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
          on-click = "${pamixer} -t";
          on-click-right = "${pavucontrol} -t 3";
          on-scroll-up = "${pamixer} -i 1";
          on-scroll-down = "${pamixer} -d 1";
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
          on-click = "${pamixer} --default-source -t";
          on-click-right = "${pavucontrol} -t 4";
          on-scroll-up = "${pamixer} --default-source -i 1";
          on-scroll-down = "${pamixer} --default-source -d 1";
          scroll-step = 5;
        };

        tray = {
          icon-size = 13;
          spacing = 13;
        };
      }];

      style = ''
        @define-color base00 ${config.lib.stylix.colors.withHashtag.base00};
        @define-color base01 ${config.lib.stylix.colors.withHashtag.base01};
        @define-color base02 ${config.lib.stylix.colors.withHashtag.base02};
        @define-color base03 ${config.lib.stylix.colors.withHashtag.base03};
        @define-color base04 ${config.lib.stylix.colors.withHashtag.base04};
        @define-color base05 ${config.lib.stylix.colors.withHashtag.base05};
        @define-color base06 ${config.lib.stylix.colors.withHashtag.base06};
        @define-color base07 ${config.lib.stylix.colors.withHashtag.base07};
        @define-color base08 ${config.lib.stylix.colors.withHashtag.base08};
        @define-color base09 ${config.lib.stylix.colors.withHashtag.base09};
        @define-color base0A ${config.lib.stylix.colors.withHashtag.base0A};
        @define-color base0B ${config.lib.stylix.colors.withHashtag.base0B};
        @define-color base0C ${config.lib.stylix.colors.withHashtag.base0C};
        @define-color base0D ${config.lib.stylix.colors.withHashtag.base0D};
        @define-color base0E ${config.lib.stylix.colors.withHashtag.base0E};
        @define-color base0F ${config.lib.stylix.colors.withHashtag.base0F};

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
            color: @base09;
            border-radius: 10px;
            margin-right: 10px;
        }

        #backlight {
            color: @base04;
            border-radius: 10px 0px 0px 10px;
            border-right: 0px;
            margin-left: 5px;
        }

        #clock {
            color: @base0C;
            border-radius: 10px;
            margin-left: 5px;
        }

        #pulseaudio {
            color: @base0A;
            border-left: 0px;
            border-right: 0px;
        }

        #pulseaudio.microphone {
            color: @base0F;
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
            color: @base09;
        }

        #workspaces button.focused {
            color: @base09;
            border-radius: 10px;
        }

        #workspaces button.urgent {
            color: @base08;
            border-radius: 10px;
        }

        #workspaces button:hover {
            color: @base02;
            border-radius: 10px;
        }
      '';
    };
  };
}
