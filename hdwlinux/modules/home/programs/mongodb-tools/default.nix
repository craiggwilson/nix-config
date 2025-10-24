{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.mongodb-tools;
in
{
  options.hdwlinux.programs.mongodb-tools = {
    enable = config.lib.hdwlinux.mkEnableOption "mongodb-tools" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.mongosh
      pkgs.mongodb-tools
    ];
  };
}
