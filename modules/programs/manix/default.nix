{
  config.substrate.modules.programs.manix = {
    provides = [
      "programs:manix"
      "programming"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.manix ];
      };
  };
}
