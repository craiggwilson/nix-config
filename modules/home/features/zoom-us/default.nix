{ options, config, lib, pkgs, ... }:

let
  cfg = config.hdwlinux.features.zoom-us;
in
{
  options.hdwlinux.features.zoom-us = {
    enable = lib.hdwlinux.mkEnableOpt [ "gui" "work" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.old-zoom.zoom-us
    ];
  };
}
