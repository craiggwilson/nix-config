{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.meld;
in
{
  options.hdwlinux.packages.meld = with types; {
    enable = mkBoolOpt false "Whether or not to enable meld.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      meld
    ];
  };
}
