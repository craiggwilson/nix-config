{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.claude-code;
in
{
  options.hdwlinux.programs.claude-code = {
    enable = config.lib.hdwlinux.mkEnableOption "claude-code" "work";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.claude-code ];
  };
}
