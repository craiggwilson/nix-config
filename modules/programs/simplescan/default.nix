{
  config.substrate.modules.programs.simplescan = {
    provides = [
      "programs:simplescan"
      "gui"
    ];
    requires = [ "hardware:scanning" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.simple-scan ];
      };
  };
}
