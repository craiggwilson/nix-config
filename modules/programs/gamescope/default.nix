{
  config.substrate.modules.programs.gamescope = {
    provides = [
      "programs:gamescope"
      "gaming"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gamescope ];
      };
  };
}
