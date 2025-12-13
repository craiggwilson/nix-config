{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.desktopEnvironments.wayland.electronSupport;
in
{
  options.hdwlinux.desktopEnvironments.wayland.electronSupport = {
    enable = lib.hdwlinux.mkEnableOption "electronSupport" config.hdwlinux.desktopEnvironments.wayland.enable;
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
