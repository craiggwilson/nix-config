{
  config.substrate.modules.programs.pre-commit = {
    tags = [ "profile:programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.pre-commit ];
      };
  };
}
