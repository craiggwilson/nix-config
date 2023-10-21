{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gh;
in
{
  options.hdwlinux.features.gh = with types; {
    enable = mkBoolOpt false "Whether or not to enable gh.";
  };

  config.hdwlinux.home.programs.gh = mkIf cfg.enable {
    enable = true;
  };
}
