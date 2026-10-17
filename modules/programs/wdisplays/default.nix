{
  config.substrate.modules.programs.wdisplays = {
    provides = [
      "programs:wdisplays"
      "gui"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wdisplays ];
      };
  };
}
