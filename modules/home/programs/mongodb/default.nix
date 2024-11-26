{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.mongodb;
in
{
  options.hdwlinux.programs.mongodb = {
    enable = config.lib.hdwlinux.mkEnableOption "mongodb" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mongodb-ce ];
  };
}
