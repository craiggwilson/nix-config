{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.features.gitkraken;
in
{
  options.hdwlinux.features.gitkraken = {
    enable = lib.hdwlinux.mkEnableOpt [
      "programming"
      "gui"
    ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ pkgs.gitkraken ];
  };
}
