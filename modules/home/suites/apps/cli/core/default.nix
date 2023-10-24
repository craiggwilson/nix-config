{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.cli.core;
in
{
  options.hdwlinux.suites.apps.cli.core = with types; {
    enable = mkBoolOpt false "Whether or not to enable the core command line apps.";
  };

  config.hdwlinux.features = mkIf cfg.enable {
    bat.enable = true;
    bc.enable = true;
    btop.enable = true;
    direnv.enable = true;
    fzf.enable = true;
    git.enable = true;
    jq.enable = true;
    lsd.enable = true;
    micro.enable = true;
    ranger.enable = true;
    ripgrep.enable = true;
    ssh.enable = true;
    starship.enable = true;
    viddy.enable = true;
    zoxide.enable = true;
  };
}
