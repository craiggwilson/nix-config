{
  config.substrate.modules.programs.watchman = {
    tags = [ "profile:programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.watchman ];
      };
  };
}
