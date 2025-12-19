{
  config.substrate.modules.programs.songtool = {
    tags = [ "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.songtool ];
      };
  };
}

