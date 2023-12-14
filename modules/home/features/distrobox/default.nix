{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.distrobox;
in
{
  options.hdwlinux.features.distrobox = with types; {
    enable = mkEnableOpt ["cli" "programming"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      distrobox
    ];
  };
}
