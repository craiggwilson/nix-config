{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.firefox;
in
{
  options.hdwlinux.packages.firefox = with types; {
    enable = mkBoolOpt false "Whether or not to enable firefox.";
  };

  config.hdwlinux.home.programs.firefox = mkIf cfg.enable {
    enable = true;
  };
}
