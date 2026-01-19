{
  config.substrate.modules.programs.slack-mcp-server = {
    tags = [
      "programming"
      "ai:mcp"
      "users:craig:work"
    ];

    homeManager =
      {
        config,
        pkgs,
        ...
      }:
      let
        secrets = config.hdwlinux.security.secrets.entries;

        mcpPackage = pkgs.writeShellScriptBin "slack-mcp-server" ''
          SLACK_MCP_XOXC_TOKEN=$(cat ${secrets.slackMcpXoxcToken.path}) \
          SLACK_MCP_XOXD_TOKEN=$(cat ${secrets.slackMcpXoxdToken.path}) \
          ${pkgs.hdwlinux.slack-mcp-server}/bin/slack-mcp-server "$@"
        '';
      in
      {
        config = {
          home.packages = [ mcpPackage ];

          hdwlinux = {
            ai.mcpServers.slack = {
              type = "stdio";
              command = "slack-mcp-server";
              args = [ ];
            };

            security.secrets.entries = {
              slackMcpXoxcToken.source = "manual";
              slackMcpXoxdToken.source = "manual";
            };
          };
        };
      };
  };
}
