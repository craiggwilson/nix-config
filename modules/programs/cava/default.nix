{
  config.substrate.modules.programs.cava = {
    provides = [
      "programs:cava"
      "hardware:audio"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.cava ];
      };
  };
}
