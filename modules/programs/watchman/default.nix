{
  config.substrate.modules.programs.watchman = {
    provides = [
      "programs:watchman"
      "programming"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.watchman ];
      };
  };
}
