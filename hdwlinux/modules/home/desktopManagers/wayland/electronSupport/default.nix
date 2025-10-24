{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.desktopManagers.wayland.electronSupport;
in
{
  options.hdwlinux.desktopManagers.wayland.electronSupport = {
    enable = lib.hdwlinux.mkEnableOption "electronSupport" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    xdg.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
      --wayland-text-input-version=3
    '';
  };
}
