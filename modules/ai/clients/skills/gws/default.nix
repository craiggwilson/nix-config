{
  config.substrate.modules.ai.clients.skills.gws = {
    provides = [
      "ai:clients:skills:gws"
      "ai:clients"
    ];
    homeManager =
      {
        pkgs,
        inputs,
        wrap,
        ...
      }:
      let
        gwsSrc = inputs.googleworkspace-cli;

        # Every gws invocation resolves its OAuth credentials (including the
        # refresh token) from secretspec at exec time: the entry is materialized
        # as an exec-time temp file and GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE —
        # which gws checks before its encrypted store or the keyring — points at
        # it. No credential material is persisted on disk.
        gws = wrap.package {
          package = gwsSrc.packages.${pkgs.stdenv.hostPlatform.system}.gws;
          secrets.scope = "gws";
        };
      in
      {
        home.packages = [ gws ];

        secretspec.entries.GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE = {
          description = "Google Workspace CLI OAuth user credentials (JSON with refresh token).";
          asPath = true;
          ref = {
            vault = "Work";
            item = "Google - Work";
            field = "gws_credentials";
          };
        };

        secretspec.scopes.gws.secrets = [
          "GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE"
        ];

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
    provides = [
      "ai:clients:skills:gws-craig-work"
      "ai:clients"
    ];
    requires = [ "profiles:work" ];
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
