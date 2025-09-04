{
  config,
  ...
}:
{
  options.hdwlinux.desktopManagers.wayland = {
    enable = config.lib.hdwlinux.mkEnableOption "wayland" false;
  };
}
