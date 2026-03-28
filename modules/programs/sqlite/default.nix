{
  config.substrate.modules.programs.sqlite = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.sqlite ];
      };
  };
}
