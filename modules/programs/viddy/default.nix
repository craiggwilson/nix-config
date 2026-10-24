{
  config.substrate.modules.programs.viddy = {
    tags = [ "profile:programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.viddy ];
      };
  };
}
