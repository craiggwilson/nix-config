{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.vlc;
in
{
  options.hdwlinux.features.vlc = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      vlc
    ];
  };
}
