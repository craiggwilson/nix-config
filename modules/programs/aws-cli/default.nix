{
  config.substrate.modules.programs.aws-cli = {
    tags = [ "users:craig:work" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.awscli2 ];
      };
  };
}

