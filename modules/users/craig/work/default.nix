{
  config.substrate.modules.users.craig.work = {
    tags = [ "users:craig:work" ];

    homeManager =
      {
        config,
        pkgs,
        lib,
        hasTag,
        wrap,
        ...
      }:
      let
        mcpPackage = wrap.withShell {
          package = pkgs.hdwlinux.mcp-atlassian;
          args = [
            "--jira-url"
            "https://jira.mongodb.org"
            "--confluence-url"
            "https://wiki.corp.mongodb.com"
          ];
          preHook = ''
            export JIRA_PERSONAL_TOKEN="$(cat ${config.hdwlinux.security.secrets.entries.jiraAccessToken.path})"
            export CONFLUENCE_PERSONAL_TOKEN="$(cat ${config.hdwlinux.security.secrets.entries.confluenceAccessToken.path})"
          '';
        };
      in
      {
        hdwlinux.ai.clients.mcpServers = lib.mkIf (hasTag "ai:clients") {
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
