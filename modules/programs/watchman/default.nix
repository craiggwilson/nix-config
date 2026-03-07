{
  config.substrate.modules.programs.watchman = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.watchman ];
      };
  };
}

