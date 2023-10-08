{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.fzf;
in
{
  options.hdwlinux.packages.fzf = with types; {
    enable = mkBoolOpt false "Whether or not to enable fzf.";
  };

  config.hdwlinux.home.programs.fzf = mkIf cfg.enable {
    enable = true;
    enableBashIntegration = config.hdwlinux.packages.bash.enable;
  };
}
