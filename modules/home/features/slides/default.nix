{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.slides;
in
{
  options.hdwlinux.features.slides = {
    enable = lib.hdwlinux.mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable { home.packages = [ pkgs.slides ]; };
}
