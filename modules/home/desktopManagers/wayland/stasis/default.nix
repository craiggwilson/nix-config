{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.stasis;
in
{
  options.hdwlinux.desktopManagers.wayland.stasis = {
    enable = lib.hdwlinux.mkEnableOption "stasis" false; # config.hdwlinux.desktopManagers.wayland.enable;
  };

  xdg.configFile."stasis/stasis.rune".text = ''
    stasis:
      pre_suspend_command "loginctl lock-session"
      monitor_media false
      respect_idle_inhibitors true

      dpms:
        timeout 60  # 1 minute
        command "screenctl power off"
        resume-command "screenctl power on"
      end
      
      lock_screen:
        timeout 300  # 5 minutes
        command "loginctl lock-session"
      end

      suspend:
        timeout 1800  # 30 minutes
        command "systemctl suspend"
      end

      on_battery:
        brightness:
          timeout 30  # 30 seconds
          command "screenctl backlight set 5"
          resume-command "screenctl backlight restore"
        end
        
        dpms:
          timeout 60  # 1 minute
          command "screenctl power off"
          resume-command "screenctl power on"
        end
        
        lock_screen:
          timeout 120  # 2 minutes
          command "loginctl lock-session"
        end
        
        suspend:
          timeout 300  # 5 minutes
          command "systemctl suspend"
        end
      end
    end
  '';

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.stasis ];

    systemd.user.services.stasis = {
      Unit = {
        Description = "Stasis Wayland Idle Manager";
        Documentation = [ "https://gitlab.com/w0lff/shikane`" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.stasis}/bin/stasis";
        Restart = "on-failure";
        Slice = "background-graphical.slice";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
