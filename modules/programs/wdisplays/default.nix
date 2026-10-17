{
  config.substrate.modules.programs.wdisplays = {
    provides = [
      "programs:wdisplays"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wdisplays ];
      };
  };
}
