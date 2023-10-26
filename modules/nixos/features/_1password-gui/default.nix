{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features._1password-gui;
in
{
  options.hdwlinux.features._1password-gui = with types; {
    enable = mkBoolOpt false "Whether or not to enable 1password gui.";
  };

  config.programs._1password-gui = mkIf cfg.enable {
    enable = true;
  };
}
