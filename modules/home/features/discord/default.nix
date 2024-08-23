{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.discord;
in
{
  options.hdwlinux.features.discord = {
    enable = lib.hdwlinux.mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config.home.packages = lib.mkIf cfg.enable [ pkgs.discord ];
}
