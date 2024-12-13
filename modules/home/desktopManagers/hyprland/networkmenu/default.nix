{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.networkmenu;
in
{
  options.hdwlinux.desktopManagers.hyprland.networkmenu = {
    enable = lib.hdwlinux.mkEnableOption "networkmenu" config.hdwlinux.desktopManagers.hyprland.rofi.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "networkmenu" (
        builtins.replaceStrings [ "networkmenu.rasi" ] [ "${./networkmenu.rasi}" ] (
          builtins.readFile ./networkmenu.sh
        )
      ))
    ];
  };
}
