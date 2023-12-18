{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.displayManager.gdm;
in
{
  options.hdwlinux.features.displayManager.gdm = with types; {
    enable = mkEnableOpt ["displayManager:gdm"] config.hdwlinux.features.tags;
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
