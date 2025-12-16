{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.github-mcp-server;

  # Create a wrapper script that runs the github MCP server with API key support
  mcpPackage = pkgs.writeShellScriptBin "github-mcp-server" ''
    # Use the pinned version instead of @latest for reproducibility
    GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.hdwlinux.security.secrets.entries.githubApiToken.path}) ${pkgs.github-mcp-server}/bin/github-mcp-server "$@"
  '';
in
{
  options.hdwlinux.programs.github-mcp-server = {
    enable = config.lib.hdwlinux.mkEnableOption "github-mcp-server" [
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ mcpPackage ];

    hdwlinux.mcpServers.github = {
      type = "stdio";
      command = "github-mcp-server";
      args = [ "stdio" ];
    };
  };
}
