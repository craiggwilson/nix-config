{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.cli;
in
{
  options.hdwlinux.suites.apps.cli = with types; {
    enable = mkBoolOpt false "Whether or not to enable the command line apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      bat.enable = true;
      btop.enable = true;
      git.enable = true;
    };
  };
}
