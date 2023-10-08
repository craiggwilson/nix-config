{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.kitty;
in
{
  options.hdwlinux.packages.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
  };

  config.hdwlinux.home.programs.kitty = mkIf cfg.enable {
    enable = true;
  };
}
