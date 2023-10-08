{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.lsd;
in
{
  options.hdwlinux.packages.lsd = with types; {
    enable = mkBoolOpt false "Whether or not to enable lsd.";
  };

  config.hdwlinux.home.programs.lsd = mkIf cfg.enable {
    enable = true;
    enableAliases = true;
  };
}
