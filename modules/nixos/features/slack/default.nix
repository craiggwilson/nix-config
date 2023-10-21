{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.slack;
in
{
  options.hdwlinux.features.slack = with types; {
    enable = mkBoolOpt false "Whether or not to enable slack.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      slack
    ];
  };
}
