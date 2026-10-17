{
  config.substrate.modules.programs.sqlite = {
    provides = [
      "programs:sqlite"
      "programming"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.sqlite ];
      };
  };
}
