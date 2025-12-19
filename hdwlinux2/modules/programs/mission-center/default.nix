{
  config.substrate.modules.programs.mission-center = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mission-center ];
      };
  };
}

