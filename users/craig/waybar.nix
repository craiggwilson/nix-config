{ lib, pkgs, config, ... }:
with lib;
let
  pamixer = "${getBin pkgs.pamixer}/bin/pamixer";
  pavucontrol = "${getBin pkgs.pavucontrol}/bin/pavucontrol";
in {
  hdwlinux.packages.waybar.settings = [{
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
      on-scroll-up = "${pamixer} -i 5";
      on-scroll-down = "${pamixer} -d 5";
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
      on-scroll-up = "${pamixer} --default-source -i 5";
      on-scroll-down = "${pamixer} --default-source -d 5";
      scroll-step = 5;
    };

    tray = {
      icon-size = 13;
      spacing = 13;
    };
  }];

  hdwlinux.packages.waybar.style = ''
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
        color: #cdd6f4;
    }

    tooltip {
        background: #1e1e2e;
        border-radius: 10px;
        border-width: 2px;
        border-style: solid;
        border-color: #11111b;
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
        background: #1e1e2e;
        padding: 0px 10px;
        margin: 3px 0px;
        border: 1px solid #181825;
    }

    #battery {
        color: #a6e3a1;
        border-radius: 10px;
        margin-right: 10px;
    }

    #backlight {
        border-radius: 10px 0px 0px 10px;
        border-left: 0px;
        border-right: 0px;
        margin-left: 5px;
    }

    #clock {
        color: #fab387;
        border-radius: 10px;
        margin-left: 5px;
    }

    #network {
        color: #f9e2af;
        border-left: 0px;
        border-right: 0px;
    }

    #pulseaudio {
        color: #89b4fa;
        border-left: 0px;
        border-right: 0px;
    }

    #pulseaudio.microphone {
        color: #cba6f7;
        border-radius: 0px 10px 10px 0px;
        border-left: 0px;
        border-right: 0px;
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
        background: #1e1e2e;
        border-radius: 10px;
        margin-left: 10px;
        padding-right: 0px;
        padding-left: 5px;
    }

    #workspaces button {
        padding: 5px;
        color: #313244;
        margin-right: 5px;
    }

    #workspaces button.active {
        color: #a6adc8;
    }

    #workspaces button.focused {
        color: #a6adc8;
        background: #eba0ac;
        border-radius: 10px;
    }

    #workspaces button.urgent {
        color: #11111b;
        background: #a6e3a1;
        border-radius: 10px;
    }

    #workspaces button:hover {
        background: #11111b;
        color: #cdd6f4;
        border-radius: 10px;
    }
  '';
}