{
  config.substrate.modules.programs.cava = {
    provides = [ "hardware:audio" ];
    tags = [ "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.cava ];
      };
  };
}
