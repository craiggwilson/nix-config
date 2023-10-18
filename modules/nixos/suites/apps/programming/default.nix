{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.programming;
in
{
  options.hdwlinux.suites.apps.programming = with types; {
    enable = mkBoolOpt false "Whether or not to enable programming apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.packages = {
      gh.enable = true;
      go.enable = true;
      goland.enable = true;
      meld.enable = true;
      podman.enable = true;
      python.enable = true;
      vscode.enable = true;
    };
  };
}
