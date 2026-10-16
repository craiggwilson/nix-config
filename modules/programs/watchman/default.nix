{
  config.substrate.modules.programs.watchman = {
    provides = [ "programs:watchman" "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.watchman ];
      };
  };
}
