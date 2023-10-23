{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.bat;
in
{
  options.hdwlinux.features.bat = with types; {
    enable = mkBoolOpt false "Whether or not to enable bat.";
  };

  config.programs.bat = mkIf cfg.enable {
    enable = true;
  };
}
