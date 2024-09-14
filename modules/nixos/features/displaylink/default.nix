{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.displaylink;
  needsDisplaylink = builtins.any (m: m.displaylink) config.hdwlinux.monitors.monitors;
in
{
  options.hdwlinux.features.displaylink = {
    enable = lib.hdwlinux.mkBoolOpt needsDisplaylink "Enable displaylink feature.";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [
      "displaylink"
      "modesetting"
    ];
  };
}
