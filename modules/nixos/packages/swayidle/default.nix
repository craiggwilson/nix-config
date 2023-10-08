{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.swayidle;
in
{
  options.hdwlinux.packages.swayidle = with types; {
    enable = mkBoolOpt false "Whether or not to enable swayidle.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
        swayidle
    ];
  };
}
