{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.jq;
in
{
  options.hdwlinux.features.jq = with types; {
    enable = mkBoolOpt false "Whether or not to enable jq.";
  };

  config.programs.jq = mkIf cfg.enable {
    enable = true;
  };
}
