{
  config.substrate.modules.programs.simplescan = {
    provides = [
      "programs:simplescan"
      "gui"
    ];
    requires = [
      "gui"
      "hardware:scanning"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.simple-scan ];
      };
  };
}
