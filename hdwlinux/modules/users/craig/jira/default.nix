{
  config.substrate.modules.users.craig.jira = {
    tags = [ "users:craig:work" ];

    homeManager =
      { config, ... }:
      {
        hdwlinux.security.secrets.entries.jiraAccessToken = {
          reference = "op://Work/Jira/personal-access-token";
        };
        hdwlinux.security.secrets.entries.jiraConfig = {
          path = "${config.home.homeDirectory}/.mongodb-jira.yaml";
          reference = "op://Work/Jira/.mongodb-jira.yaml";
          mode = "0600";
        };
      };
  };
}
