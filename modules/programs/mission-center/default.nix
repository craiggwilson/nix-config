{
  config.substrate.modules.programs.mission-center = {
    provides = [
      "programs:mission-center"
      "gui"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mission-center ];
      };
  };
}
