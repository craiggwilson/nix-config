{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.pavucontrol;
in
{
  options.hdwlinux.features.pavucontrol = with types; {
    enable = mkBoolOpt false "Whether or not to enable pavucontrol.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      pavucontrol
    ];
  };
}
