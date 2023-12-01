{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.ripgrep;
in
{
  options.hdwlinux.features.ripgrep = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config.programs.ripgrep = mkIf cfg.enable {
    enable = true;
  };
}
