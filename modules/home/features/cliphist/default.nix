{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.cliphist; 
in {
  
  options.hdwlinux.features.cliphist = with types; {
    enable = mkBoolOpt false "Whether or not to enable cliphist.";
  };

  config.home.packages = with pkgs; mkIf cfg.enable [
    cliphist
    wl-clipboard
  ];
}