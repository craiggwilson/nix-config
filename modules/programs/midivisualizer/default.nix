{
  config.substrate.modules.programs.midivisualizer = {
    provides = [ "programs:midivisualizer" "audio:midi" ];
    requires = [ "gui" ];
    tags = [
      "audio:midi"
      "gui"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.midivisualizer ];
      };
  };
}
