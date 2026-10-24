{
  config.substrate.modules.programs.aws-cli = {
    tags = [
      "user:craig"
      "profile:work"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.awscli2 ];
      };
  };
}
