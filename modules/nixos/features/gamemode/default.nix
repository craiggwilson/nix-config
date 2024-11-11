{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.gamemode;
in
{
  options.hdwlinux.features.gamemode = {
    enable = lib.hdwlinux.mkEnableOpt [ "gaming" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs.gamemode = {
      enable = true;
    };
  };
}
