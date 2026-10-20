{
  config.substrate.modules.programs.simplescan = {
    tags = [
      "desktop"
      "scanning"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.simple-scan ];
      };
  };
}
