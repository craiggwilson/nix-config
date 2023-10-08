{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.nautilus;
in
{
  options.hdwlinux.packages.nautilus = with types; {
    enable = mkBoolOpt false "Whether or not to enable nautilus.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        gnome.nautilus
    ];
  };
}
