{
  config.substrate.modules.programs.freetube = {
    provides = [
      "programs:freetube"
      "gui"
    ];
    requires = [ "profiles:personal" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.freetube ];
      };
  };
}
