{
  config.substrate.modules.programs.pre-commit = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.pre-commit ];
      };
  };
}

