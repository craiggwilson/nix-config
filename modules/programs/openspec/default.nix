{
  config.substrate.modules.programs.openspec = {
    tags = [
      "profile:programming"
      "profile:ai"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.openspec ];
      };
  };
}
