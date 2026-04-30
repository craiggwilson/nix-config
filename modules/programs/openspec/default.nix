{
  config.substrate.modules.programs.openspec = {
    tags = [
      "programming"
      "ai:clients"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.openspec ];
      };
  };
}
