{
  config.substrate.modules.programs.freetube = {
    tags = [
      "desktop"
      "users:craig:personal"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.freetube ];
      };
  };
}
