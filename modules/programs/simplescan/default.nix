{
  config.substrate.modules.programs.simplescan = {
    tags = [ "gui" "scanning" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.simple-scan ];
      };
  };
}

