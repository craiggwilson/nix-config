{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.ripgrep;
in
{
  options.hdwlinux.packages.ripgrep = with types; {
    enable = mkBoolOpt false "Whether or not to enable ripgrep.";
  };

  config.hdwlinux.home.programs.ripgrep = mkIf cfg.enable {
    enable = true;
  };
}