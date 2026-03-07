{
  config.substrate.modules.programs.ghostty = {
    tags = [ "gui" ];

    homeManager =
      { config, lib, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors or { };
        hasColors = colors != { };
      in
      {
        hdwlinux.apps.terminal = {
          package = config.programs.ghostty.package;
          desktopName = "ghostty.desktop";
          argGroups = {
            launch = [ "-e" ];
          };
        };

        programs.ghostty = {
          enable = true;
          package = pkgs.ghostty;
          enableBashIntegration = config.programs.bash.enable;
          enableZshIntegration = config.programs.zsh.enable;

          settings = {
            theme = "hdwlinux";
            gtk-titlebar = false;
            font-family = "FiraCode Nerd Font Mono";
            font-size = 11;
            keybind = [
              "ctrl+v=paste_from_clipboard"
              "performable:ctrl+c=copy_to_clipboard"
              "ctrl+shift+left=csi:1;6D"
              "ctrl+shift+right=csi:1;6C"
            ];
          };

          themes = lib.mkIf hasColors {
            hdwlinux = {
              background = colors.base00;
              cursor-color = colors.base06;
              foreground = colors.base05;
              palette = [
                "0=#${colors.base03}"
                "1=#${colors.base08}"
                "2=#${colors.base0B}"
                "3=#${colors.base0A}"
                "4=#${colors.base0D}"
                "5=#${colors.base17}"
                "6=#${colors.base0C}"
                "7=#${colors.base05}"
                "8=#${colors.base04}"
                "9=#${colors.base08}"
                "10=#${colors.base0B}"
                "11=#${colors.base0A}"
                "12=#${colors.base0D}"
                "13=#${colors.base17}"
                "14=#${colors.base0C}"
                "15=#${colors.base07}"
              ];
              selection-background = colors.base02;
              selection-foreground = colors.base05;
            };
          };
        };
      };
  };
}

