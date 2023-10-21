{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.brightnessctl;
in
{
  options.hdwlinux.features.brightnessctl = with types; {
    enable = mkBoolOpt false "Whether or not to enable brightnessctl.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        brightnessctl
    ];
  };
}
