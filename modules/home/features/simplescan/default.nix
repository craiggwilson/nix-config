{
  options,
  config,
  pkgs,
  lib,
  host ? "",
  format ? "",
  inputs ? { },
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.simplescan;
in
{
  options.hdwlinux.features.simplescan = with types; {
    enable = mkBoolOpt false "Whether or not to configure simplescan.";
  };

  config.home.packages = with pkgs.gnome; mkIf cfg.enable [ simple-scan ];
}
