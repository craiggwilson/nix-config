{
  config.substrate.modules.programs.simplescan = {
    provides = [ "programs:simplescan" "gui" ];
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
