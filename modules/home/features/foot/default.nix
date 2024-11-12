{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.features.foot;
in
{
  options.hdwlinux.features.foot = {
    enable = lib.hdwlinux.mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "FiraCode Nerd Font Mono:size=11,monospace:size=11";
        };

        key-bindings = {
          clipboard-paste = "Control+v";
        };

        colors =
          with config.hdwlinux.theme.colors;
          lib.mkIf config.hdwlinux.theme.enable {
            alpha = 0.6;
            foreground = base05;
            background = base00;
            regular0 = base00;
            regular1 = base08;
            regular2 = base0B;
            regular3 = base0A;
            regular4 = base0D;
            regular5 = base0E;
            regular6 = base0C;
            regular7 = base05;
            bright0 = base02;
            bright1 = base08;
            bright2 = base0B;
            bright3 = base0A;
            bright4 = base0D;
            bright5 = base0E;
            bright6 = base0C;
            bright7 = base07;
            "16" = base09;
            "17" = base0F;
            "18" = base01;
            "19" = base02;
            "20" = base04;
            "21" = base06;
          };
      };
    };
  };
}
