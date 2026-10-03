{
  config.substrate.modules.users.craig.work = {
    tags = [ "users:craig:work" ];

    homeManager =
      {
        config,
        pkgs,
        lib,
        wrap,
        hasTag,
        ...
      }:
      let
        # secretspec resolves work_mcp at exec time; the arguments carrying the
        # tokens sit on the core, inside that chain, so they expand afterwards.
        mcp = wrap.package {
          package = pkgs.hdwlinux.mcp-atlassian;
          secrets.scope = "work_mcp";
          args = [
            "--jira-url"
            "https://jira.mongodb.org"
            "--confluence-url"
            "https://wiki.corp.mongodb.com"
            "--jira-personal-token"
            "\"\$JIRA_ACCESS_TOKEN\""
            "--confluence-personal-token"
            "\"\$CONFLUENCE_ACCESS_TOKEN\""
          ];
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
            command = lib.getExe mcp;
            args = [ ];
          };
          glean.http.url = "https://mongodb-be.glean.com/mcp/default";
        };

        secretspec = {
          entries = {
            JIRA_ACCESS_TOKEN = {
              description = "Personal access token for the MongoDB Jira instance.";
              ref = {
                vault = "Work";
                item = "Jira";
                field = "personal-access-token";
              };
            };
            jiraConfig = {
              description = "Jira CLI configuration for the MongoDB instance.";
              ref = {
                vault = "Work";
                item = "Jira";
                field = ".mongodb-jira.yaml";
              };
              file.path = "${config.home.homeDirectory}/.mongodb-jira.yaml";
            };
            CONFLUENCE_ACCESS_TOKEN = {
              description = "Personal access token for the MongoDB Confluence instance.";
              ref = {
                vault = "Work";
                item = "Confluence";
                field = "personal-access-token";
              };
            };
          };
          scopes.work_mcp.secrets = [
            "JIRA_ACCESS_TOKEN"
            "CONFLUENCE_ACCESS_TOKEN"
          ];
        };
      };
  };
}
