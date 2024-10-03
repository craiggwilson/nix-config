{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.waypipe;
in
{
  options.hdwlinux.features.waypipe = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:remote" ] config.hdwlinux.features.tags;
  };

  config.environment.systemPackages = lib.mkIf cfg.enable [
    pkgs.waypipe
    pkgs.xorg.xauth
  ];
}
