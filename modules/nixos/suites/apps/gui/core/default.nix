{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.gui.core;
in
{
  options.hdwlinux.suites.apps.gui.core = with types; {
    enable = mkBoolOpt false "Whether or not to enable the core command line apps.";
  };

  config = {
    hdwlinux.features = mkIf cfg.enable {
      _1password-gui.enable = true;
      stylix.enable = true;
    };
  };
}
