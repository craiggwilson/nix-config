{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.zoom-us;
in
{
  options.hdwlinux.packages.zoom-us = with types; {
    enable = mkBoolOpt false "Whether or not to enable zoom-us.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      zoom-us
    ];
  };
}
