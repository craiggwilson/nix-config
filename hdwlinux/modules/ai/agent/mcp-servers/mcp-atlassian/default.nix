{
  config.substrate.modules.ai.agent.mcp-servers.mcp-atlassian = {
    tags = [
      "ai:agent"
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
        hasSecrets = secrets ? jiraAccessToken && secrets ? confluenceAccessToken;

        mcpPackage = pkgs.writeShellScriptBin "mcp-atlassian" ''
          ${pkgs.hdwlinux.mcp-atlassian}/bin/mcp-atlassian \
          --jira-url https://jira.mongodb.org \
          --jira-personal-token $(cat ${secrets.jiraAccessToken.path}) \
          --confluence-url https://wiki.corp.mongodb.com \
          --confluence-personal-token $(cat ${secrets.confluenceAccessToken.path}) \
          "$@"
        '';
      in
      {
        config = lib.mkIf hasSecrets {
          home.packages = [ mcpPackage ];

          hdwlinux.ai.agent.mcpServers.atlassian.stdio = {
            command = "mcp-atlassian";
            args = [ ];
          };
        };
      };
  };
}
