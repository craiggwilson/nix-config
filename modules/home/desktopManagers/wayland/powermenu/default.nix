{
  config,
  lib,
  pkgs,
  flake,
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

    xdg.configFile."rofi/powermenu.rasi".source =
      config.lib.file.mkOutOfStoreSymlink "${flake}/modules/home/desktopManagers/wayland/powermenu/powermenu.rasi";

    home.packages = [
      (pkgs.writeShellScriptBin "powermenu" (builtins.readFile ./powermenu.sh))
    ];
  };
}
