{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.cli;
in
{
  options.hdwlinux.suites.apps.cli = with types; {
    enable = mkBoolOpt false "Whether or not to enable the command line apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      bat.enable = true;
      btop.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      git.enable = true;
      jq.enable = true;
      lsd.enable = true;
      micro.enable = true;
      neofetch.enable = true;
      nvtop.enable = true;
      procps.enable = true;
      ranger.enable = true;
      ripgrep.enable = true;
      ssh.enable = true;
      starship.enable = true;
      zoxide.enable = true;
    };
  };
}
