{
  config.substrate.modules.programs.viddy = {
    provides = [ "programs:viddy" "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.viddy ];
      };
  };
}
