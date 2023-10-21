{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.protonup-qt;
in
{
  options.hdwlinux.features.protonup-qt = with types; {
    enable = mkBoolOpt false "Whether or not to enable protonup-qt.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [
      protonup-qt
    ];
  };
}
