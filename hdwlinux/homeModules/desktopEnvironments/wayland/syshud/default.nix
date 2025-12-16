{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.syshud;
in
{
  options.hdwlinux.desktopEnvironments.wayland.syshud = {
    enable = lib.hdwlinux.mkEnableOption "syshud" config.hdwlinux.desktopEnvironments.wayland.enable;
  };

  config = lib.mkIf cfg.enable {

    xdg.configFile."sys64/hud/colors.css".text = lib.mkIf config.hdwlinux.theme.enable ''
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

    xdg.configFile."sys64/hud/style.css".source = ./style.css;

    systemd.user.services.syshud = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "Simple system status indicator.";
        Documentation = "https://github.com/System64fumo/syshud";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.syshud}/bin/syshud -o horizontal -p topmiddle";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
