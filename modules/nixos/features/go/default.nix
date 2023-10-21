{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.go;
in
{
  options.hdwlinux.features.go = with types; {
    enable = mkBoolOpt false "Whether or not to enable go.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.go.enable = true;

    hdwlinux.home.packages = with pkgs; [
      gotools
    ];
  };
}
