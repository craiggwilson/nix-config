{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.workspace-mcp;

  # Create a wrapper script that runs the Google Workspace MCP server with configuration
  mcpPackage = pkgs.writeShellScriptBin "workspace-mcp" ''
    GOOGLE_OAUTH_CLIENT_ID="$(cat ${config.hdwlinux.security.secrets.entries.workspaceMcpClientID.path})" \
    GOOGLE_OAUTH_CLIENT_SECRET="$(cat ${config.hdwlinux.security.secrets.entries.workspaceMcpClientSecret.path})" \
    USER_GOOGLE_EMAIL="${cfg.userEmail}" \
    ${pkgs.hdwlinux.workspace-mcp}/bin/workspace-mcp \
      --single-user \
      --tools ${lib.concatStringsSep " " cfg.tools} \
      --tool-tier ${cfg.toolTier} \
      "$@"
  '';
in
{
  options.hdwlinux.programs.workspace-mcp = {
    enable = config.lib.hdwlinux.mkEnableOption "workspace-mcp" [
      "programming"
      "work"
    ];

    tools = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "gmail"
          "drive"
          "calendar"
          "docs"
          "sheets"
          "chat"
          "forms"
          "slides"
          "tasks"
          "search"
        ]
      );
      default = [
        "drive"
        "docs"
        "sheets"
        "slides"
      ];
      description = "Specific tools to enable.";
    };

    toolTier = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "core"
          "extended"
          "complete"
        ]
      );
      default = "core";
      description = "Tool tier to load (core, extended, or complete)";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "User email to run the MCP server as.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ mcpPackage ];

    hdwlinux.mcpServers.google-workspace = {
      type = "stdio";
      command = "workspace-mcp";
      args = [ ];
    };
  };
}
