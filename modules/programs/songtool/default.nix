{
  config.substrate.modules.programs.songtool = {
    tags = [ "capability:audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.songtool ];
      };
  };
}
