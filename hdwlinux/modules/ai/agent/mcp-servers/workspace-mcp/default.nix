{
  config.substrate.modules.programs.workspace-mcp = {
    tags = [
      "users:craig:work"
      "programming"
      "ai:mcp"
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.hdwlinux.programs.workspace-mcp;
        secrets = config.hdwlinux.security.secrets.entries;
        hasSecrets = secrets ? workspaceMcpClientID && secrets ? workspaceMcpClientSecret;

        mcpPackage = pkgs.writeShellScriptBin "workspace-mcp" ''
          GOOGLE_OAUTH_CLIENT_ID="$(cat ${secrets.workspaceMcpClientID.path})" \
          GOOGLE_OAUTH_CLIENT_SECRET="$(cat ${secrets.workspaceMcpClientSecret.path})" \
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
            default = "";
            description = "User email to run the MCP server as.";
          };
        };

        config = lib.mkIf hasSecrets {
          home.packages = [ mcpPackage ];

          hdwlinux.ai.agent.mcpServers.google-workspace.stdio = {
            command = "workspace-mcp";
            args = [ ];
          };
        };
      };
  };
}
