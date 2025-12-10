{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.context7;

  # Create a wrapper script that runs the context7 MCP server with API key support
  mcpPackage = pkgs.writeShellScriptBin "context7" ''
    # Ensure Node.js and npm are available in PATH
    export PATH="${pkgs.nodejs}/bin:${pkgs.nodePackages.npm}/bin:$PATH"

    # Use the pinned version instead of @latest for reproducibility
    exec ${pkgs.nodejs}/bin/npx -y @upstash/context7-mcp@1.0.31 "$@"
  '';
in
{
  options.hdwlinux.programs.context7 = {
    enable = config.lib.hdwlinux.mkEnableOption "context7" [
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ mcpPackage ];

    hdwlinux.mcpServers.context7 = {
      type = "stdio";
      command = "context7";
      args = [ ];
    };
  };
}
