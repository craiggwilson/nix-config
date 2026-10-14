{
  config.substrate.modules.programs.jira-cli = {
    tags = [ "users:craig:work" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        wrap,
        ...
      }:
      let
        # jira-cli reads JIRA_API_TOKEN from the environment before falling back
        # to the keyring (locked when no session is active). The wrapper resolves
        # the secret at exec time; preHook runs after that resolution, so it can
        # map the injected secret onto the variable the CLI reads.
        hasToken = config.secretspec.entries ? JIRA_ACCESS_TOKEN;
        jira = wrap.package {
          package = pkgs.jira-cli-go;
          secrets.scope = "jira";
          preHook = ''export JIRA_API_TOKEN="$JIRA_ACCESS_TOKEN"'';
        };
      in
      {
        home.packages = lib.mkIf hasToken [ jira ];

        # Static client config for MongoDB's Jira Server instance. The token is
        # NOT stored here — it is injected by the wrapper. `installation: Local`
        # (capital L) selects the REST API v2 endpoints; jira.mongodb.org has no
        # v3 search API.
        xdg.configFile.".jira/.config.yml".text = ''
          installation: Local
          server: https://jira.mongodb.org
          login: craig.wilson@mongodb.com
          auth_type: bearer
        '';

        secretspec.scopes.jira.secrets = lib.mkIf hasToken [
          "JIRA_ACCESS_TOKEN"
        ];
      };
  };
}
