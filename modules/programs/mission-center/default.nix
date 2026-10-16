{
  config.substrate.modules.programs.mission-center = {
    provides = [ "programs:mission-center" "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mission-center ];
      };
  };
}
