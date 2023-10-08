{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.slack;
in
{
  options.hdwlinux.packages.slack = with types; {
    enable = mkBoolOpt false "Whether or not to enable slack.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      slack
    ];
  };
}
