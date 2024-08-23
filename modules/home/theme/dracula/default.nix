{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.theme.dracula;
  name = "Dracula";
  wallpaper = ./assets/background.png;
in
{

  options.hdwlinux.theme.dracula = with types; {
    enable = mkBoolOpt false "Whether or not to enable the dracula theme.";
  };

  config = mkIf cfg.enable {
    hdwlinux.theme = {
      enable = mkDefault true;
      name = "dracula";
      colors = inputs.themes.dracula;
      wallpapers = [ wallpaper ];
    };

    hdwlinux.features.vscode.theme = name;
    programs.vscode.extensions = with pkgs.vscode-extensions; [ dracula-theme.theme-dracula ];

    gtk = {
      theme = {
        name = name;
        package = pkgs.dracula-theme;
      };

      iconTheme = mkDefault {
        name = name;
        package = pkgs.dracula-icon-theme;
      };
    };

    home.sessionVariables.GTK_THEME = name;

    dconf.settings = mkIf config.hdwlinux.features.gnome.enable {
      "org/gnome/shell/extensions/user-theme" = {
        name = name;
      };
    };
  };
}
