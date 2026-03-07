{
  config.substrate.modules.programs.wdisplays = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wdisplays ];
      };
  };
}

