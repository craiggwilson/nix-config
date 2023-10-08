{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.dconf;
in
{
  options.hdwlinux.packages.dconf = with types; {
    enable = mkBoolOpt false "Whether or not to enable dconf.";
  };

  config = mkIf cfg.enable {
    programs.dconf.enable = true;
  };
}
