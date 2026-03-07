{
  config.substrate.modules.programs.manix = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.manix ];
      };
  };
}

