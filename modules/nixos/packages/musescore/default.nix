{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.musescore;
in
{
  options.hdwlinux.packages.musescore = with types; {
    enable = mkBoolOpt false "Whether or not to enable musescore.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      musescore
    ];
  };
}
