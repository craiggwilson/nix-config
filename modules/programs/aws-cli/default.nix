{
  config.substrate.modules.programs.aws-cli = {
    provides = [ "programs:aws-cli" "profiles:work" ];
    tags = [ "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.awscli2 ];
      };
  };
}
