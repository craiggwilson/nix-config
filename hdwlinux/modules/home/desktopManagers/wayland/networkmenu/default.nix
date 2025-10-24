{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.networkmenu;
in
{
  options.hdwlinux.desktopManagers.wayland.networkmenu = {
    enable = lib.hdwlinux.mkEnableOption "networkmenu" config.hdwlinux.desktopManagers.wayland.rofi.enable;
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
