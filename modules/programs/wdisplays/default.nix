{
  config.substrate.modules.programs.wdisplays = {
    provides = [ "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wdisplays ];
      };
  };
}
