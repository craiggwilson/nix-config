{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.gitkraken;
in
{
  options.hdwlinux.programs.gitkraken = {
    enable = config.lib.hdwlinux.mkEnableAllOption "gitkraken" [
      "gui"
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gitkraken ];
  };
}
