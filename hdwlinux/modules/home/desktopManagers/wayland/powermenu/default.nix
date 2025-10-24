{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.powermenu;
in
{
  options.hdwlinux.desktopManagers.wayland.powermenu = {
    enable = lib.hdwlinux.mkEnableOption "powermenu" config.hdwlinux.desktopManagers.wayland.rofi.enable;
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
