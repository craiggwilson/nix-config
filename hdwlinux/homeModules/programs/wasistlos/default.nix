{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.wasistlos;
in
{
  options.hdwlinux.programs.wasistlos = {
    enable = config.lib.hdwlinux.mkEnableOption "wasistlos" [
      "gui"
      "personal"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wasistlos ];
  };
}
