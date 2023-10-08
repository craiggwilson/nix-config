{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.fonts;
in
{
  options.hdwlinux.packages.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to enable fonts.";
  };

  config.hdwlinux.home.packages = with pkgs; mkIf cfg.enable [
     (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
