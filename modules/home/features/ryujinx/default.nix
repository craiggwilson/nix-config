{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.ryujinx;
in
{
  options.hdwlinux.features.ryujinx = with types; {
    enable = mkEnableOpt [
      "gaming"
      "gui"
    ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ pkgs.ryujinx ]; };
}
