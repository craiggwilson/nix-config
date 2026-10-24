{
  config.substrate.modules.programs.minder = {
    tags = [ "desktop" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.minder ];
      };
  };
}
