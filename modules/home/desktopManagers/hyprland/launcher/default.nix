{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.launcher;
in
{
  options.hdwlinux.desktopManagers.hyprland.launcher = {
    enable = lib.hdwlinux.mkEnableOption "launcher" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.hdwlinux.writeSwitchedShellApplication {
        name = "launchctl";
        runtimeInputs = [
          config.programs.rofi.package
          pkgs.procps
          pkgs.uwsm
        ];
        subcommands = {
          exec = "uwsm app -- \"$@\"";
          show-menu = builtins.replaceStrings [ "launchctl-menu.rasi" ] [ "${./launchctl-menu.rasi}" ] (
            builtins.readFile ./launchctl-menu.sh
          );
        };
      })
    ];
  };
}
