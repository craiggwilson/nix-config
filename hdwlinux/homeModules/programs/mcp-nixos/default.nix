{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.mcp-nixos;
in
{
  options.hdwlinux.programs.mcp-nixos = {
    enable = config.lib.hdwlinux.mkEnableOption "mcp-nixos" [
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.mcpServers.nixos = {
      type = "stdio";
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      args = [ ];
    };
  };
}
