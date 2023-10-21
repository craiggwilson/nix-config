{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.simplescan;
in
{
  options.hdwlinux.features.simplescan = with types; {
    enable = mkBoolOpt false "Whether or not to configure simplescan.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs.gnome; [
      simple-scan
    ];
  };
}
