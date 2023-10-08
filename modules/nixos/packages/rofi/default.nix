{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.rofi;
in
{
  options.hdwlinux.packages.rofi = with types; {
    enable = mkBoolOpt false "Whether or not to enable rofi.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };
  };
}
