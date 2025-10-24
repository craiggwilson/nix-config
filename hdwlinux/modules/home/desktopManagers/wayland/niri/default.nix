{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.desktopManagers.wayland.niri;
in
{
  options.hdwlinux.desktopManagers.wayland.niri = {
    enable = config.lib.hdwlinux.mkEnableOption "niri" "desktop:niri";
  };

  config = lib.mkIf cfg.enable {
    systemd.user.startServices = true;

    home.sessionVariables.NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";

    xdg.configFile."niri".source =
      config.lib.file.mkOutOfStoreSymlink "${flake}/modules/home/desktopManagers/wayland/niri/config";
  };
}
