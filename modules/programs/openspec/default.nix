{
  config.substrate.modules.programs.openspec = {
    tags = [
      "programming"
      "ai:agent"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.openspec ];
      };
  };
}
