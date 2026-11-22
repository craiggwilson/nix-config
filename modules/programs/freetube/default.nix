{
  config.substrate.modules.programs.freetube = {
    tags = [
      "desktop"
      "profile:media"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.freetube ];
      };
  };
}
