{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.services.core;
in
{
  options.hdwlinux.suites.services.core = with types; {
    enable = mkBoolOpt false "Whether or not to enable core services.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      onedrive.enable = true;
      xdg.enable = true;
    };

    systemd.user.startServices = true;
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
