{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.direnv;
in
{
  options.hdwlinux.features.direnv = with types; {
    enable = mkBoolOpt false "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
