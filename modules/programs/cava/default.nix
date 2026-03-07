{
  config.substrate.modules.programs.cava = {
    tags = [ "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.cava ];
      };
  };
}

