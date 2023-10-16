{ options, config, pkgs, lib, host ? "", format ? "", inputs ? { }, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.packages.simplescan;
in
{
  options.hdwlinux.packages.simplescan = with types; {
    enable = mkBoolOpt false "Whether or not to configure simplescan.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs.gnome; [
      simple-scan
    ];
  };
}
