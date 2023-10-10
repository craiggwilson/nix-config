{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.gdm;
in
{
  options.hdwlinux.packages.gdm = with types; {
    enable = mkBoolOpt false "Whether or not to enable gdm.";
    wayland = mkBoolOpt true "Whether or not to enable wayland.";
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
