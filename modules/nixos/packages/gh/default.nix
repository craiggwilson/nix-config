{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.gh;
in
{
  options.hdwlinux.packages.gh = with types; {
    enable = mkBoolOpt false "Whether or not to enable gh.";
  };

  config.hdwlinux.home.programs.gh = mkIf cfg.enable {
    enable = true;
  };
}
