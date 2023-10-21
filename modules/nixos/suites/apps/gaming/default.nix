{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.gaming;
in
{
  options.hdwlinux.suites.apps.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable gaming apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      protonup-qt.enable = true;
      steam.enable = true;
    };
  };
}
