{
  config.substrate.modules.programs.jira-cli = {
    tags = [ "users:craig:work" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.jira-cli-go ];
      };
  };
}
