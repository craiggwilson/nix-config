{
  config.substrate.modules.programs.midivisualizer = {
    provides = [
      "programs:midivisualizer"
      "audio:midi"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.midivisualizer ];
      };
  };
}
