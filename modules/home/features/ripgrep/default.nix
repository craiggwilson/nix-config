{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.ripgrep;
in
{
  options.hdwlinux.features.ripgrep = with types; {
    enable = mkBoolOpt false "Whether or not to enable ripgrep.";
  };

  config.programs.ripgrep = mkIf cfg.enable {
    enable = true;
  };
}
