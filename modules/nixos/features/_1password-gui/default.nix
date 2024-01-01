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

  config = mkIf cfg.enable {
    programs._1password-gui = {
      enable = true;
    };

    security.pam.services."1password".enableGnomeKeyring = true;
  };
}
