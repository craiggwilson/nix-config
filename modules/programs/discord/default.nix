{
  config.substrate.modules.programs.discord = {
    provides = [
      "programs:discord"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.discord ];
      };
  };
}
