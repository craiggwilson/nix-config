{
  config.substrate.modules.programs.minder = {
    provides = [ "apps:minder" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.minder ];
      };
  };
}
