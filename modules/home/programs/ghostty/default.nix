{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.ghostty;
in
{
  options.hdwlinux.programs.ghostty = {
    enable = config.lib.hdwlinux.mkEnableOption "ghostty" "gui";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.apps.terminal = {
      package = config.programs.ghostty.package;
      desktopName = "ghostty.desktop";
    };

    programs.ghostty = {
      enable = true;
      enableBashIntegration = config.hdwlinux.programs.bash.enable;
      enableZshIntegration = config.hdwlinux.programs.zsh.enable;

      settings = {
        theme = "hdwlinux";
        gtk-titlebar = false;
        font-family = "FiraCode Nerd Font Mono";
        font-size = 11;
        keybind = [
          "ctrl+v=paste_from_clipboard"
          "performable:ctrl+c=copy_to_clipboard"
        ];
      };

      themes = {
        hdwlinux = {
          background = "1e1e2e";
          cursor-color = "f5e0dc";
          foreground = "cdd6f4";
          palette = [
            "0=#45475a"
            "1=#f38ba8"
            "2=#a6e3a1"
            "3=#f9e2af"
            "4=#89b4fa"
            "5=#f5c2e7"
            "6=#94e2d5"
            "7=#bac2de"
            "8=#585b70"
            "9=#f38ba8"
            "10=#a6e3a1"
            "11=#f9e2af"
            "12=#89b4fa"
            "13=#f5c2e7"
            "14=#94e2d5"
            "15=#a6adc8"
          ];
          selection-background = "353749";
          selection-foreground = "cdd6f4";
        };
      };
    };
  };
}
