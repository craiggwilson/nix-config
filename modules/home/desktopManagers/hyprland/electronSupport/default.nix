{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.desktopManagers.hyprland.electronSupport;
in
{
  options.hdwlinux.desktopManagers.hyprland.electronSupport = {
    enable = lib.hdwlinux.mkEnableOption "electronSupport" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    xdg.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
    '';
  };
}
