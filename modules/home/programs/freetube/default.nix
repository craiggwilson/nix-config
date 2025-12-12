{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.freetube;
in
{
  options.hdwlinux.programs.freetube = {
    enable = config.lib.hdwlinux.mkEnableOption "freetube" [
      "gui"
      "personal"
    ];
  };

  config = lib.mkIf cfg.enable {
    programs.freetube = {
      enable = true;
    };
  };
}
