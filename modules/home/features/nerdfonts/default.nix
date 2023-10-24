{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.nerdfonts;
in
{
  options.hdwlinux.features.nerdfonts = with types; {
    enable = mkBoolOpt false "Whether or not to enable nerdfonts.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
     (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
