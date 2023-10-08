{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.calibre;
in
{
  options.hdwlinux.packages.calibre = with types; {
    enable = mkBoolOpt false "Whether or not to enable calibre.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      calibre
    ];
  };
}
