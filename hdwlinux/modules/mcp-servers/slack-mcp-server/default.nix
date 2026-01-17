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
        lib,
        pkgs,
        ...
      }:
      let
        secrets = config.hdwlinux.security.secrets.entries;
        hasSecrets = secrets ? slackMcpXoxcToken && secrets ? slackMcpXoxdToken;

        mcpPackage = pkgs.writeShellScriptBin "slack-mcp-server" ''
          SLACK_MCP_XOXC_TOKEN=$(cat ${secrets.slackMcpXoxcToken.path}) \
          SLACK_MCP_XOXD_TOKEN=$(cat ${secrets.slackMcpXoxdToken.path}) \
          ${pkgs.hdwlinux.slack-mcp-server}/bin/slack-mcp-server "$@"
        '';
      in
      {
        config = lib.mkIf hasSecrets {
          home.packages = [ mcpPackage ];

          hdwlinux.mcpServers.slack = {
            type = "stdio";
            command = "slack-mcp-server";
            args = [ ];
          };
        };
      };
  };
}
