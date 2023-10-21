{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.nix-ld;
in
{
  options.hdwlinux.features.nix-ld = with types; {
    enable = mkBoolOpt false "Whether or not to enable nix-ld.";
  };

  config.programs.nix-ld = mkIf cfg.enable {
    enable = true;
  };
}
