{
  config.substrate.modules.programs.pre-commit = {
    provides = [ "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.pre-commit ];
      };
  };
}
