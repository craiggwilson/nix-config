{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.udiskie;
in
{
  options.hdwlinux.packages.udiskie = with types; {
    enable = mkBoolOpt false "Whether or not to enable the udiskie service.";
  };

  config = mkIf cfg.enable {
    services.udisks2.enable = true;
    hdwlinux.home.services.udiskie = {
      enable = true;
      automount = true;
      tray = "auto";
    };
  };
}
