{
  config.substrate.modules.programs.meld = {
    tags = [
      "desktop"
      "programming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.meld ];
      };
  };
}
