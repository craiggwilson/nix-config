{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.btop;
in
{
  options.hdwlinux.features.btop = with types; {
    enable = mkBoolOpt false "Whether or not to enable btop.";
  };

  config.hdwlinux.home.programs.btop = mkIf cfg.enable {
     enable = true;
  };
}
