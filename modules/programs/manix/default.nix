{
  config.substrate.modules.programs.manix = {
    provides = [ "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.manix ];
      };
  };
}
