{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.mcp-context7;

  # Create a wrapper script that runs the context7 MCP server with API key support
  mcpPackage = pkgs.writeShellScriptBin "mcp-context7" ''
    # Ensure Node.js and npm are available in PATH
    export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.npm}/bin:$PATH"

    # Use the pinned version instead of @latest for reproducibility
    exec ${pkgs.nodejs}/bin/npx -y @upstash/context7-mcp@1.0.31 "$@"
  '';
in
{
  options.hdwlinux.programs.mcp-context7 = {
    enable = config.lib.hdwlinux.mkEnableOption "mcp-context7" [
      "programming"
    ];

    apiKey = lib.mkOption {
      description = "Context7 API key for higher rate limits and private repositories";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ mcpPackage ];

    hdwlinux.mcpServers.context7 = {
      type = "stdio";
      command = "mcp-context7";
      args = [ ];
    };
  };
}
