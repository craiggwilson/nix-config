{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.desktop.gnome;
in
{
  options.hdwlinux.features.desktop.gnome = with types; {
    enable = mkEnableOpt [ "desktop:gnome" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs.gnomeExtensions; [
      appindicator
      arc-menu
      blur-my-shell
      burn-my-windows
      dash-to-panel
      space-bar
      tray-icons-reloaded
      user-themes
      vitals
    ];

    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "arcmenu@arcmenu.com"
          "blur-my-shell@aunetx"
          #"burn-my-windows@schneegans.github.com"
          "dash-to-panel@jderose9.github.com"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          "space-bar@luchrioh"
          "trayIconsReloaded@selfmade.pl"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          #"Vitals@CoreCoding.com"
        ];
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file:///${builtins.elemAt config.hdwlinux.theme.wallpapers 0}";
        picture-uri-dark = "file:///${builtins.elemAt config.hdwlinux.theme.wallpapers 0}";
      };
      "org/gnome/desktop/interface" = {
        color-scheme = lib.mkIf config.hdwlinux.theme.dark "prefer-dark";
        enable-hot-corners = false;
      };
    };
  };
}
