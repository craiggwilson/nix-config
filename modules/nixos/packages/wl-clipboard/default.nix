{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.wl-clipboard; 
in {
  
  options.hdwlinux.packages.wl-clipboard = with types; {
    enable = mkBoolOpt false "Whether or not to enable wl-clipboard.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wl-clipboard
    ];
  };
}
