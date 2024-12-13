{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.appmenu;
in
{
  options.hdwlinux.desktopManagers.hyprland.appmenu = {
    enable = lib.hdwlinux.mkEnableOption "appmenu" config.hdwlinux.desktopManagers.hyprland.rofi.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "appmenu" (
        builtins.replaceStrings [ "appmenu.rasi" ] [ "${./appmenu.rasi}" ] (builtins.readFile ./appmenu.sh)
      ))
    ];
  };
}
