{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.video.displaylink;
  needsDisplaylink = builtins.any (m: m.displaylink) config.hdwlinux.monitors;
in
{
  options.hdwlinux.features.video.displaylink = {
    enable = lib.hdwlinux.mkBoolOpt needsDisplaylink "Enable displaylink feature.";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [
      "displaylink"
      "modesetting"
    ];
  };
}
