{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.mcp-grafana;
in
{
  options.hdwlinux.programs.mcp-grafana = {
    enable = config.lib.hdwlinux.mkEnableOption "mcp-grafana" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mcp-grafana ];
  };
}
