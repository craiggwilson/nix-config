{
  config.substrate.modules.programs.freetube = {
    tags = [
      "desktop"
      "profile:personal"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.freetube ];
      };
  };
}
