{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.services.gui;
in
{
  options.hdwlinux.suites.services.gui = with types; {
    enable = mkBoolOpt false "Whether or not to enable gui services.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      xembed-sni-proxy.enable = true;
    };

    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
