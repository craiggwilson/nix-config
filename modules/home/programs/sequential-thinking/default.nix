{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.sequential-thinking;

  # Create a wrapper script that runs the sequential-thinking MCP server with API key support
  mcpPackage = pkgs.writeShellScriptBin "sequential-thinking" ''
    # Ensure Node.js and npm are available in PATH
    export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.npm}/bin:$PATH"

    # Use the pinned version instead of @latest for reproducibility
    exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-sequential-thinking@2025.11.25 "$@"
  '';
in
{
  options.hdwlinux.programs.sequential-thinking = {
    enable = config.lib.hdwlinux.mkEnableOption "sequential-thinking" [
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ mcpPackage ];

    hdwlinux.mcpServers.sequential-thinking = {
      type = "stdio";
      command = "sequential-thinking";
      args = [ ];
    };
  };
}
