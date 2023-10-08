{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.jq;
in
{
  options.hdwlinux.packages.jq = with types; {
    enable = mkBoolOpt false "Whether or not to enable jq.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.jq.enable = true;
  };
}
