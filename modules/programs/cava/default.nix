{
  config.substrate.modules.programs.cava = {
    tags = [ "capability:audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.cava ];
      };
  };
}
