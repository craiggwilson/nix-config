{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.displayManager.gdm;
in
{
  options.hdwlinux.suites.displayManager.gdm = with types; {
    enable = mkBoolOpt false "Whether or not to enable the gdm display manager.";
  };

  config = mkIf cfg.enable {
    hdwlinux.packages = {
        gdm.enable = true;
    };
  };
}