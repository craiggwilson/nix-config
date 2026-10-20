{
  config.substrate.modules.programs.midivisualizer = {
    tags = [
      "audio:midi"
      "desktop"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.midivisualizer ];
      };
  };
}
