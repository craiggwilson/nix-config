{
  config.substrate.modules.programs.gamescope = {
    tags = [
      "profile:gaming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gamescope ];
      };
  };
}
