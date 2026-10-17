{
  config.substrate.modules.programs.mission-center = {
    provides = [
      "programs:mission-center"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mission-center ];
      };
  };
}
