{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.networkmenu;
in
{
  options.hdwlinux.desktopEnvironments.wayland.networkmenu = {
    enable = lib.hdwlinux.mkEnableOption "networkmenu" config.hdwlinux.desktopEnvironments.wayland.rofi.enable;
  };

  config = lib.mkIf cfg.enable {

    xdg.configFile."rofi/networkmenu.rasi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/hdwlinux/homeModules/desktopEnvironments/wayland/networkmenu/networkmenu.rasi";

    home.packages = [
      (pkgs.writeShellScriptBin "networkmenu" (builtins.readFile ./networkmenu.sh))
    ];
  };
}
