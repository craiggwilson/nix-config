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
      (pkgs.writeShellApplication {
        name = "launcher-exec";
        runtimeInputs = [
          pkgs.uwsm
        ];
        text = builtins.readFile ./launcher-exec.sh;
      })
      (pkgs.writeShellApplication {
        name = "launcher-menu";
        runtimeInputs = [
          config.programs.rofi.package
          pkgs.procps
        ];
        text = builtins.replaceStrings [ "launcher-menu.rasi" ] [ "${./launcher-menu.rasi}" ] (
          builtins.readFile ./launcher-menu.sh
        );
      })
    ];
  };
}
