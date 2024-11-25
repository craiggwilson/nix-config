{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.nasc;
in
{
  options.hdwlinux.programs.nasc = {
    enable = config.lib.hdwlinux.mkEnableOption "nasc" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nasc ];

    home.shellAliases = {
      nasc = "com.github.parnold_x.nasc";
    };
  };
}
