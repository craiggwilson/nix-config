{
  config.substrate.modules.users.craig.work.gws = {
    tags = [
      "user:craig:work"
      "profile:ai"
    ];

    homeManager =
      {
        config,
        ...
      }:
      {
        secretspec.entries.gwsClientSecret = {
          description = "Google Workspace CLI OAuth client secret for the CLI's own credentials.";
          ref = {
            vault = "Work";
            item = "google-api-oauth";
            field = "client_secret.json";
          };
          file.path = "${config.xdg.configHome}/gws/client_secret.json";
        };
      };
  };
}
