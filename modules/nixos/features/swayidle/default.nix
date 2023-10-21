{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.swayidle;
in
{
  options.hdwlinux.features.swayidle = with types; {
    enable = mkBoolOpt false "Whether or not to enable swayidle.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
        swayidle
    ];
  };
}
