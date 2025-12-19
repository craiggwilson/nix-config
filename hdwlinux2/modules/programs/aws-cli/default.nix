{
  config.substrate.modules.programs.aws-cli = {
    tags = [ "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.awscli2 ];
      };
  };
}

