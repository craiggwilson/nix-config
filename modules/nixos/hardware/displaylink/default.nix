{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.hardware.displaylink;
  needsDisplaylink = builtins.any (m: m.displaylink) config.hdwlinux.hardware.monitors;
in
{
  options.hdwlinux.hardware.displaylink = {
    enable = lib.mkOption {
      description = "Whether to enable displaylink.";
      type = lib.types.bool;
      default = needsDisplaylink;
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [
      "displaylink"
    ];
  };
}
