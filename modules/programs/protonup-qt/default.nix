{
  config.substrate.modules.programs.protonup-qt = {
    tags = [
      "desktop"
      "gaming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.protonup-qt ];
      };
  };
}
