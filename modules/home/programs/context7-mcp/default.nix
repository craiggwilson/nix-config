{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.context7-mcp;
in
{
  options.hdwlinux.programs.context7-mcp = {
    enable = config.lib.hdwlinux.mkEnableOption "context7-mcp" [
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ pkgs.hdwlinux.context7-mcp ];

    hdwlinux.mcpServers.context7-mcp = {
      type = "stdio";
      command = "context7-mcp";
      args = [ ];
    };
  };
}
