{
  config.substrate.modules.programs.gamescope = {
    provides = [ "gaming" ];
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
