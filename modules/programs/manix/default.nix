{
  config.substrate.modules.programs.manix = {
    provides = [ "programs:manix" "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.manix ];
      };
  };
}
