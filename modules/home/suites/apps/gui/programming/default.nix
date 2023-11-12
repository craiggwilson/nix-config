{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.gui.programming;
in
{
  options.hdwlinux.suites.apps.gui.programming = with types; {
    enable = mkBoolOpt false "Whether or not to enable programming apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      goland.enable = true;
      idea-community.enable = true;
      meld.enable = true;
      vscode.enable = true;
    };
  };
}
