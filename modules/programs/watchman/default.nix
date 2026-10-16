{
  config.substrate.modules.programs.watchman = {
    provides = [ "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.watchman ];
      };
  };
}
