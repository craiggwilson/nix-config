{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features._1password-gui;
in
{
  options.hdwlinux.features._1password-gui = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config.programs._1password-gui = mkIf cfg.enable {
    enable = true;
  };
}
