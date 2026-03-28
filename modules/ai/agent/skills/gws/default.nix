{
  config.substrate.modules.ai.agent.skills.gws = {
    tags = [
      "ai:agent"
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

        hdwlinux.ai.agent.skills = {
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

  config.substrate.modules.ai.agent.skills.gws-craig-work = {
    tags = [
      "ai:agent"
      "users:craig:work"
    ];

    homeManager =
      { config, ... }:
      {
        hdwlinux.security.secrets.entries.gwsClientSecret = {
          path = "${config.xdg.configHome}/gws/client_secret.json";
          reference = "op://Work/google-api-oauth/client_secret.json";
          mode = "0600";
        };
      };
  };
}
