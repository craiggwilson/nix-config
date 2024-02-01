{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.zoom-us;
in
{
  options.hdwlinux.features.zoom-us = with types; {
    enable = mkEnableOpt ["gui" "work"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      zoom-us
    ];
  };
}
