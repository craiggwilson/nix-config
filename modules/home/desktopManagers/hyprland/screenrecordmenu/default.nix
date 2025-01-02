{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.screenrecordmenu;
in
{
  options.hdwlinux.desktopManagers.hyprland.screenrecordmenu = {
    enable = lib.hdwlinux.mkEnableOption "screenrecordmenu" config.hdwlinux.desktopManagers.hyprland.rofi.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "screenrecordmenu" (
        builtins.replaceStrings [ "screenrecordmenu.rasi" ] [ "${./screenrecordmenu.rasi}" ] (
          builtins.readFile ./screenrecordmenu.sh
        )
      ))
    ];
  };
}
