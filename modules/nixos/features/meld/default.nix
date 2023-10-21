{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.meld;
in
{
  options.hdwlinux.features.meld = with types; {
    enable = mkBoolOpt false "Whether or not to enable meld.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      meld
    ];
  };
}
