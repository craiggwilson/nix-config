{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.gimp;
in
{
  options.hdwlinux.packages.gimp = with types; {
    enable = mkBoolOpt false "Whether or not to enable gimp.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      gimp
    ];
  };
}
