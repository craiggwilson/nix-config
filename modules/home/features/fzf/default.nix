{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.fzf;
in
{
  options.hdwlinux.features.fzf = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config.programs.fzf = mkIf cfg.enable {
    enable = true;
    enableBashIntegration = config.hdwlinux.features.bash.enable;
  };
}
