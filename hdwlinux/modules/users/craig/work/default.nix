{
  config.substrate.modules.users.craig.work = {
    tags = [ "users:craig:work" ];

    homeManager =
      {
        config,
        pkgs,
        lib,
        hasTag,
        ...
      }:
      let
        mcpPackage = pkgs.writeShellScriptBin "mcp-atlassian" ''
          ${pkgs.hdwlinux.mcp-atlassian}/bin/mcp-atlassian \
          --jira-url "https://jira.mongodb.org" \
          --jira-personal-token $(cat ${config.hdwlinux.security.secrets.entries.jiraAccessToken.path}) \
          --confluence-url "https://wiki.corp.mongodb.com" \
          --confluence-personal-token $(cat ${config.hdwlinux.security.secrets.entries.confluenceAccessToken.path}) \
          "$@"
        '';
      in
      {
        hdwlinux.ai.agent.mcpServers = lib.mkIf (hasTag "ai:agent") {
          augment-context-engine.stdio = {
            command = lib.getExe pkgs.hdwlinux.auggie;
            args = [
              "--mcp"
              "--mcp-auto-workspace"
            ];
          };
          mcp-atlassian.stdio = {
            command = lib.getExe mcpPackage;
            args = [ ];
          };
          glean.http.url = "https://mongodb-be.glean.com/mcp/default";
        };

        hdwlinux.security.secrets.entries = {
          jiraAccessToken = {
            reference = "op://Work/Jira/personal-access-token";
          };
          jiraConfig = {
            path = "${config.home.homeDirectory}/.mongodb-jira.yaml";
            reference = "op://Work/Jira/.mongodb-jira.yaml";
            mode = "0600";
          };
          confluenceAccessToken = {
            reference = "op://Work/Confluence/personal-access-token";
          };
        };
      };
  };
}
