{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.brightnessctl;
in
{
  options.hdwlinux.packages.brightnessctl = with types; {
    enable = mkBoolOpt false "Whether or not to enable brightnessctl.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        brightnessctl
    ];
  };
}
