{
  config.substrate.modules.programs.sqlite = {
    provides = [ "programs:sqlite" "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.sqlite ];
      };
  };
}
