{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gnome;
in
{
  options.hdwlinux.features.gnome = with types; {
    enable = mkEnableOpt ["desktop:gnome"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      gnomeExtensions.user-themes
      gnomeExtensions.tray-icons-reloaded
      gnomeExtensions.vitals
      gnomeExtensions.dash-to-panel
      gnomeExtensions.sound-output-device-chooser
      gnomeExtensions.space-bar
    ];

    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions = [
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "trayIconsReloaded@selfmade.pl"
          "Vitals@CoreCoding.com"
          "dash-to-panel@jderose9.github.com"
          "sound-output-device-chooser@kgshank.net"
          "space-bar@luchrioh"
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
