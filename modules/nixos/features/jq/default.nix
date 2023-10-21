{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.jq;
in
{
  options.hdwlinux.features.jq = with types; {
    enable = mkBoolOpt false "Whether or not to enable jq.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.jq.enable = true;
  };
}
