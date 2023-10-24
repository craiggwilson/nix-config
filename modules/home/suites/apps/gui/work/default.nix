{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.gui.work;
in
{
  options.hdwlinux.suites.apps.gui.work = with types; {
    enable = mkBoolOpt false "Whether or not to enable graphical work apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      slack.enable = true;
      zoom-us.enable = true;
    };
  };
}
