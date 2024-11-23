{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.gamemode;
in
{
  options.hdwlinux.programs.gamemode = {
    enable = config.lib.hdwlinux.features.mkEnableOption "gamemode" "gaming";
  };

  config = lib.mkIf cfg.enable {
    programs.gamemode = {
      enable = true;
    };
  };
}
