{
  config.substrate.modules.programs.viddy = {
    provides = [ "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.viddy ];
      };
  };
}
