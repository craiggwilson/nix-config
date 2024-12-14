{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.screenshotmenu;
in
{
  options.hdwlinux.desktopManagers.hyprland.screenshotmenu = {
    enable = lib.hdwlinux.mkEnableOption "screenshotmenu" config.hdwlinux.desktopManagers.hyprland.rofi.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "screenshotmenu" (
        builtins.replaceStrings [ "screenshotmenu.rasi" ] [ "${./screenshotmenu.rasi}" ] (
          builtins.readFile ./screenshotmenu.sh
        )
      ))
    ];
  };
}
