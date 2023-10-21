{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.displayManagers.gdm;
in
{
  options.hdwlinux.suites.displayManagers.gdm = with types; {
    enable = mkBoolOpt false "Whether or not to enable the gdm display manager.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
        gdm.enable = true;
    };
  };
}
