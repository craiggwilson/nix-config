{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.screenshot;
in
{
  options.hdwlinux.desktopManagers.hyprland.screenshot = {
    enable = lib.hdwlinux.mkEnableOption "screenshot" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "screenshot-menu";
        runtimeInputs = [
          config.programs.rofi.package
          pkgs.hyprshot
        ];
        text = builtins.replaceStrings [ "screenshot-menu.rasi" ] [ "${./screenshot-menu.rasi}" ] (
          builtins.readFile ./screenshot-menu.sh
        );
      })
    ];
  };
}
