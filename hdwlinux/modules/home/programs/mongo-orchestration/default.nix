{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.mongo-orchestration;
in
{
  options.hdwlinux.programs.mongo-orchestration = {
    enable = config.lib.hdwlinux.mkEnableOption "mongo-orchestration" "work";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hdwlinux.mongo-orchestration ];

    xdg.dataFile."mongo-orchestration/configurations" = {
      source = ./configurations;
      recursive = true;
    };

    home.sessionVariables = {
      MONGO_ORCHESTRATION_HOME = "$XDG_DATA_HOME/mongo-orchestration";
    };
  };
}
