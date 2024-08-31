{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.displaylink;
in
{
  options.hdwlinux.features.displaylink = {
    enable = lib.hdwlinux.mkBoolOpt false "Enable displaylink feature.";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [
      "displaylink"
      "modesetting"
    ];
  };
}
