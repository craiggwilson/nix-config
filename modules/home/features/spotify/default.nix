{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.spotify;
in
{
  options.hdwlinux.features.spotify = with types; {
    enable = mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config = {
    home.packages = with pkgs; mkIf cfg.enable [ spotify ];
  };
}
