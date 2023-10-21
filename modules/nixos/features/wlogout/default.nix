{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.wlogout;
in
{
  options.hdwlinux.features.wlogout = with types; {
    enable = mkBoolOpt false "Whether or not to enable wlogout.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.wlogout = {
      enable = true;
      layout = [
        {
          label = "lock";
          action = "swaylock";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "logout";
          action = "hyprctl dispatch exit";
          text = "Logout";
          keybind = "e";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
      ];

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
          background-image: none;
        }
        window {
          background-color: rgba(12, 12, 12, 0.9);
        }
        
        button {
          color: @base03;
          background-color: @base01;
          border-style: solid;
          border-width: 2px;
          background-repeat: no-repeat;
          background-position: center;
          background-size: 25%;
        }

        button:hover {
          background-color: @base02;
          outline-style: none;
        }

        #lock {
          margin: 10px;
          border-radius: 20px;
          background-image: image(url("${./assets/lock.png}"));
        }

        #logout {
          margin: 10px;
          border-radius: 20px;
          background-image: image(url("${./assets/logout.png}"));
        }

        #reboot {
          margin: 10px;
          border-radius: 20px;
          background-image: image(url("${./assets/reboot.png}"));
        }

        #shutdown {
          margin: 10px;
          border-radius: 20px;
          background-image: image(url("${./assets/shutdown.png}"));
        }
      '';
    };
  };
}
