{
  config.substrate.modules.programs.meld = {
    tags = [
      "desktop"
      "profile:programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.meld ];
      };
  };
}
