{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.lsd;
in
{
  options.hdwlinux.features.lsd = with types; {
    enable = mkEnableOpt ["cli"] config.hdwlinux.features.tags;
  };

  config.programs.lsd = mkIf cfg.enable {
    enable = true;
    enableAliases = true;
  };
}
