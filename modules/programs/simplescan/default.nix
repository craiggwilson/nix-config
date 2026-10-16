{
  config.substrate.modules.programs.simplescan = {
    provides = [ "gui" ];
    requires = [ "hardware:scanning" ];
    tags = [
      "gui"
      "scanning"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.simple-scan ];
      };
  };
}
