{
  config.substrate.modules.ai.clients.skills.gws = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      {
        pkgs,
        inputs,
        ...
      }:
      let
        gwsSrc = inputs.googleworkspace-cli;
      in
      {
        home.packages = [ inputs.googleworkspace-cli.packages.${pkgs.stdenv.hostPlatform.system}.gws ];

        hdwlinux.ai.clients.skills = {
          gws-shared = "${gwsSrc}/skills/gws-shared";
          gws-drive = "${gwsSrc}/skills/gws-drive";
          gws-drive-upload = "${gwsSrc}/skills/gws-drive-upload";
          gws-docs = "${gwsSrc}/skills/gws-docs";
          gws-docs-write = "${gwsSrc}/skills/gws-docs-write";
          gws-sheets = "${gwsSrc}/skills/gws-sheets";
          gws-sheets-read = "${gwsSrc}/skills/gws-sheets-read";
          gws-sheets-append = "${gwsSrc}/skills/gws-sheets-append";
        };

      };
  };

  config.substrate.modules.ai.clients.skills.gws-craig-work = {
    tags = [
      "ai:clients"
      "users:craig:work"
    ];

    homeManager =
      { config, ... }:
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
