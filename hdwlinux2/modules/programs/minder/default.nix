{
  config.substrate.modules.programs.minder = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.minder ];
      };
  };
}

