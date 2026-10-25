{
  config.substrate.modules.programs.aws-cli = {
    tags = [
      "user:craig"
      "profile:work"
      "profile:programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.awscli2 ];
      };
  };
}
