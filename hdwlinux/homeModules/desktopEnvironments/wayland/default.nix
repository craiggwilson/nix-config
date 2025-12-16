{
  config,
  ...
}:
{
  options.hdwlinux.desktopEnvironments.wayland = {
    enable = config.lib.hdwlinux.mkEnableOption "wayland" (
      config.hdwlinux.desktopEnvironments.wayland.hyprland.enable
      || config.hdwlinux.desktopEnvironments.wayland.niri.enable
    );
  };
}
