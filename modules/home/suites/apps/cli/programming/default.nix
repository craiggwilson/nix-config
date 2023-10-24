{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.cli.programming;
in
{
  options.hdwlinux.suites.apps.cli.programming = with types; {
    enable = mkBoolOpt false "Whether or not to enable programming cli apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      gh.enable = true;
      go.enable = true;
      python.enable = true;
    };
  };
}
