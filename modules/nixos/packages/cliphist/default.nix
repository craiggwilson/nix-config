{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.cliphist; 
in {
  
  options.hdwlinux.packages.cliphist = with types; {
    enable = mkBoolOpt false "Whether or not to enable cliphist.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cliphist
      wl-clipboard
    ];
  };
}

