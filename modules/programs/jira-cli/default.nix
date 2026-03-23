{
  config.substrate.modules.programs.jira-cli = {
    tags = [ "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.jira-cli-go ];
      };
  };
}
