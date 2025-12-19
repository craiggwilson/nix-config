{
  config.substrate.modules.programs.midivisualizer = {
    tags = [ "audio:midi" "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.midivisualizer ];
      };
  };
}

