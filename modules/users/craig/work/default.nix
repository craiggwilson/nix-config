{
  config.substrate.modules.users.craig.work = {
    tags = [
      "user:craig:work"
      "core:security:secrets"
    ];

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
        # secretspec injects the variables mcp-atlassian reads when it starts.
        mcp = wrap.package {
          package = pkgs.hdwlinux.mcp-atlassian;
          secrets.scope = "work_mcp";
          args = [
            "--jira-url"
            "https://jira.mongodb.org"
            "--confluence-url"
            "https://wiki.corp.mongodb.com"
          ];
        };
      in
      {
        hdwlinux.ai.clients.mcpServers = lib.mkIf (hasTag "profile:ai") {
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
            JIRA_PERSONAL_TOKEN = {
              description = "Personal access token for the MongoDB Jira MCP server.";
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
            CONFLUENCE_PERSONAL_TOKEN = {
              description = "Personal access token for the MongoDB Confluence MCP server.";
              ref = {
                vault = "Work";
                item = "Confluence";
                field = "personal-access-token";
              };
            };
          };
          scopes.work_mcp.secrets = [
            "JIRA_PERSONAL_TOKEN"
            "CONFLUENCE_PERSONAL_TOKEN"
          ];
        };
      };
  };
}
