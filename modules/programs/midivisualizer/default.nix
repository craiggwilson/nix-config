{
  config.substrate.modules.programs.midivisualizer = {
    tags = [
      "capability:midi"
      "desktop"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.midivisualizer ];
      };
  };
}
