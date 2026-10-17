{
  config.substrate.modules.programs.discord = {
    provides = [
      "programs:discord"
      "gui"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.discord ];
      };
  };
}
