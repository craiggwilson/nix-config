{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.app;
in
{
  options.hdwlinux.desktopManagers.hyprland.app = {
    enable = lib.hdwlinux.mkEnableOption "app" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
        name = "appctl";
        runtimeInputs = [
          config.programs.rofi.package
          pkgs.procps
          pkgs.uwsm
        ];
        subcommands = {
          exec = "uwsm app -- \"$@\"";
          show-menu = ''
            pkill rofi || rofi \
              -show drun \
              -theme ${./app-menu.rasi} \
              -run-command 'appctl exec {cmd}'
          '';
          show-windows = "pkill rofi || rofi -show window";
        };
      })
    ];
  };
}
