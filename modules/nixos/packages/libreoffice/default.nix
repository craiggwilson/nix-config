{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.libreoffice;
in
{
  options.hdwlinux.packages.libreoffice = with types; {
    enable = mkBoolOpt false "Whether or not to enable libreoffice.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      libreoffice
    ];
  };
}
