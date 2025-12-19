{
  config.substrate.modules.programs.gamescope = {
    tags = [ "gui" "gaming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gamescope ];
      };
  };
}

