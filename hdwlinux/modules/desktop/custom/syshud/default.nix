{
  config.substrate.modules.desktop.custom.syshud = {
    tags = [ "desktop:custom" ];

    homeManager =
      { config, lib, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors or { };
        hasColors = colors != { } && builtins.hasAttr "withHashtag" colors;
      in
      {
        xdg.configFile."sys64/hud/colors.css".text = lib.mkIf hasColors ''
          @define-color base00 ${colors.withHashtag.base00};
          @define-color base01 ${colors.withHashtag.base01};
          @define-color base02 ${colors.withHashtag.base02};
          @define-color base03 ${colors.withHashtag.base03};
          @define-color base04 ${colors.withHashtag.base04};
          @define-color base05 ${colors.withHashtag.base05};
          @define-color base06 ${colors.withHashtag.base06};
          @define-color base07 ${colors.withHashtag.base07};
          @define-color base08 ${colors.withHashtag.base08};
          @define-color base09 ${colors.withHashtag.base09};
          @define-color base0A ${colors.withHashtag.base0A};
          @define-color base0B ${colors.withHashtag.base0B};
          @define-color base0C ${colors.withHashtag.base0C};
          @define-color base0D ${colors.withHashtag.base0D};
          @define-color base0E ${colors.withHashtag.base0E};
          @define-color base0F ${colors.withHashtag.base0F};
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
  };
}

