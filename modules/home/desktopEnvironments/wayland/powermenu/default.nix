{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.powermenu;
in
{
  options.hdwlinux.desktopEnvironments.wayland.powermenu = {
    enable = lib.hdwlinux.mkEnableOption "powermenu" config.hdwlinux.desktopEnvironments.wayland.rofi.enable;
  };

  config = lib.mkIf cfg.enable {

    xdg.configFile."rofi/powermenu.rasi".source =
      config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/home/desktopEnvironments/wayland/powermenu/powermenu.rasi";

    home.packages = [
      (pkgs.writeShellScriptBin "powermenu" (builtins.readFile ./powermenu.sh))
    ];
  };
}
