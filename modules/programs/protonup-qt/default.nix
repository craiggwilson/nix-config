{
  config.substrate.modules.programs.protonup-qt = {
    tags = [
      "desktop"
      "profile:gaming"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.protonup-qt ];
      };
  };
}
