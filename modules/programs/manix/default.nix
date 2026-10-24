{
  config.substrate.modules.programs.manix = {
    tags = [ "profile:programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.manix ];
      };
  };
}
