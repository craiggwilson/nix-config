{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.suites.displayManagers.gdm;
in
{
  options.hdwlinux.suites.displayManagers.gdm = with types; {
    enable = mkBoolOpt false "Whether or not to enable the gdm display manager.";
  };

  config.services.xserver = mkIf cfg.enable {
    enable = true;
    layout = "us";
    libinput.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };
}
