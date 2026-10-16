{
  config.substrate.modules.programs.wdisplays = {
    provides = [ "programs:wdisplays" "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wdisplays ];
      };
  };
}
