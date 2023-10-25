{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.udiskie;
in
{
  options.hdwlinux.features.udiskie = with types; {
    enable = mkBoolOpt false "Whether or not to enable the udiskie service.";
  };

  config.services.udiskie = mkIf cfg.enable {
    enable = true;
    automount = true;
    tray = "auto";
  };
}
