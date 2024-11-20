{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.gamemode;
in
{
  options.hdwlinux.programs.gamemode = {
    enable = lib.hdwlinux.mkEnableTagsOpt "gamemode" [ "gaming" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    programs.gamemode = {
      enable = true;
    };
  };
}
