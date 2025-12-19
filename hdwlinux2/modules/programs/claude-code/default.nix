{
  config.substrate.modules.programs.claude-code = {
    tags = [ "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.claude-code ];
      };
  };
}

