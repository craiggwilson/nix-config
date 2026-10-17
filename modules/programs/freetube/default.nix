{
  config.substrate.modules.programs.freetube = {
    provides = [
      "programs:freetube"
      "gui"
    ];
    requires = [
      "gui"
      "profiles:personal"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.freetube ];
      };
  };
}
