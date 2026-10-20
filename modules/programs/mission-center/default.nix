{
  config.substrate.modules.programs.mission-center = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mission-center ];
      };
  };
}
