{
  config.substrate.modules.programs.cava = {
    provides = [ "programs:cava" "hardware:audio" ];
    tags = [ "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.cava ];
      };
  };
}
