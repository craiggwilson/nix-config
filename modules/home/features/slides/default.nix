{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.slides;
in
{
  options.hdwlinux.features.slides = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      slides
    ];
  };
}
