{
  config.substrate.modules.programs.midivisualizer = {
    provides = [ "audio:midi" ];
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
