{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.nautilus;
in
{
  options.hdwlinux.features.nautilus = with types; {
    enable = mkBoolOpt false "Whether or not to enable nautilus.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        gnome.nautilus
    ];
  };
}
