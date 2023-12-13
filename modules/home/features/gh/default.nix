{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gh;
in
{
  options.hdwlinux.features.gh = with types; {
    enable = mkEnableOpt ["cli" "programming"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
    };
    programs.gh-dash = {
      enable = true;
    };
  };
}
