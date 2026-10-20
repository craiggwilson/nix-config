{
  config.substrate.modules.programs.gamescope = {
    tags = [
      "gaming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gamescope ];
      };
  };
}
