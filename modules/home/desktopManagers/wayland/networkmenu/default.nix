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

    xdg.configFile."rofi/networkmenu.rasi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/home/desktopManagers/wayland/networkmenu/networkmenu.rasi";

    home.packages = [
      (pkgs.writeShellScriptBin "networkmenu" (builtins.readFile ./networkmenu.sh))
    ];
  };
}
