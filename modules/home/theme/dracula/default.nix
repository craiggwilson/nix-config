{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
let
  cfg = config.hdwlinux.theme.dracula;
  name = "Dracula";
  wallpaper = ./assets/background.png;
in
{

  options.hdwlinux.theme.dracula = {
    enable = config.lib.hdwlinux.mkEnableOption "dracula" "theming:dracula";
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.theme = {
      enable = lib.mkDefault true;
      name = "dracula";
      colors = inputs.themes.dracula;
      dark = true;
      wallpapers = [ wallpaper ];
    };

    hdwlinux.programs.vscode.theme = name;
    programs.vscode.extensions = with pkgs.vscode-extensions; [ dracula-theme.theme-dracula ];

    gtk = {
      theme = {
        name = name;
        package = pkgs.dracula-theme;
      };

      iconTheme = lib.mkDefault {
        name = name;
        package = pkgs.dracula-icon-theme;
      };
    };

    home.sessionVariables.GTK_THEME = name;

    dconf.settings = lib.mkIf config.hdwlinux.features.desktop.gnome.enable {
      "org/gnome/shell/extensions/user-theme" = {
        name = name;
      };
    };
  };
}
