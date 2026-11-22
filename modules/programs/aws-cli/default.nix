{
  config.substrate.modules.programs.aws-cli = {
    tags = [
      "profile:cloud-infrastructure"
      "profile:programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.awscli2 ];
      };
  };
}
