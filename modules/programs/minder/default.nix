{
  config.substrate.modules.programs.minder = {
    provides = [ "programs:minder" "apps:minder" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.minder ];
      };
  };
}
