{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.go;
in
{
  options.hdwlinux.features.go = with types; {
    enable = mkEnableOpt ["cli" "programming"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.go.enable = true;

    home.packages = with pkgs; [
      gotools
    ];
  };
}
