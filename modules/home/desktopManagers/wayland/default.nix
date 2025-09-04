{
  config,
  ...
}:
{
  options.hdwlinux.desktopManagers.wayland = {
    enable = config.lib.hdwlinux.mkEnableOption "wayland" (
      config.hdwlinux.desktopManagers.wayland.hyprland.enable
      || config.hdwlinux.desktopManagers.wayland.niri.enable
    );
  };
}
