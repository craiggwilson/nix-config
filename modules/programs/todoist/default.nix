{
  config.substrate.modules.programs.todoist = {
    tags = [ "user:craig" ];

    homeManager =
      {
        pkgs,
        wrap,
        ...
      }:
      let
        todoist = wrap.package {
          package = pkgs.todoist-cli;
          secrets.scope = "todoist";
        };
      in
      {
        home.packages = [ todoist ];

        secretspec.entries.TODOIST_API_TOKEN = {
          description = "Todoist API token shared by the Todoist CLI and Noctalia widget.";
          ref = {
            vault = "Craig";
            item = "Todoist";
            field = "token";
          };
        };

        secretspec.scopes.todoist.secrets = [ "TODOIST_API_TOKEN" ];
      };
  };
}
