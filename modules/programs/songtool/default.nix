{
  config.substrate.modules.programs.songtool = {
    provides = [ "hardware:audio" ];
    tags = [ "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.songtool ];
      };
  };
}
