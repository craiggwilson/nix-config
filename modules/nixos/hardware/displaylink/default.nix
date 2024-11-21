{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware.displaylink;
  needsDisplaylink = builtins.any (m: m.displaylink) config.hdwlinux.monitors;
in
{
  options.hdwlinux.hardware.displaylink = {
    enable = lib.hdwlinux.mkBoolOpt needsDisplaylink "Whether to enable displaylink.";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [
      "displaylink"
    ];
  };
}
