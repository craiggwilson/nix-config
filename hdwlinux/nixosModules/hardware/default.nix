{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware;
in
{
  options.hdwlinux.hardware = {
    monitors = lib.hdwlinux.sharedOptions.hardware.monitors;
  };

  config = {
    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.hardware.monitors = cfg.monitors;
      }
    ];
  };
}
