{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.powermenu;
in
{
  options.hdwlinux.desktopManagers.hyprland.powermenu = {
    enable = lib.hdwlinux.mkEnableOption "powermenu" config.hdwlinux.desktopManagers.hyprland.rofi.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "powermenu" (
        builtins.replaceStrings [ "powermenu.rasi" ] [ "${./powermenu.rasi}" ] (
          builtins.readFile ./powermenu.sh
        )
      ))
    ];
  };
}
