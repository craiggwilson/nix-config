{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.gui.gaming;
in
{
  options.hdwlinux.suites.apps.gui.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable gaming apps.";
  };

  config.hdwlinux.features = mkIf cfg.enable {
    legends-of-runeterra.enable = true;
    lutris.enable = true;
    protonup-qt.enable = true;
    steam.enable = true;
    wine.enable = true;
  };
}
