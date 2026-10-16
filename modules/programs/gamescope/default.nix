{
  config.substrate.modules.programs.gamescope = {
    provides = [ "programs:gamescope" "gaming" ];
    requires = [ "gui" ];
    tags = [
      "gui"
      "gaming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gamescope ];
      };
  };
}
