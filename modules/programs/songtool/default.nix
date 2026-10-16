{
  config.substrate.modules.programs.songtool = {
    provides = [ "programs:songtool" "hardware:audio" ];
    tags = [ "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.songtool ];
      };
  };
}
