{
  config.substrate.modules.programs.viddy = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.viddy ];
      };
  };
}

