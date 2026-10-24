{
  config.substrate.modules.programs.simplescan = {
    tags = [
      "desktop"
      "capability:scanning"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.simple-scan ];
      };
  };
}
