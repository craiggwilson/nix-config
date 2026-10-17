{
  config.substrate.modules.programs.viddy = {
    provides = [
      "programs:viddy"
      "programming"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.viddy ];
      };
  };
}
