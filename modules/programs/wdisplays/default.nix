{
  config.substrate.modules.programs.wdisplays = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wdisplays ];
      };
  };
}
