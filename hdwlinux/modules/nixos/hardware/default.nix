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
    monitors = lib.mkOption {
      description = "Options to set the monitor configuration.";
      type = lib.types.attrsOf lib.hdwlinux.types.monitor;
    };
  };

  config = {
    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.hardware.monitors = cfg.monitors;
      }
    ];
  };
}
