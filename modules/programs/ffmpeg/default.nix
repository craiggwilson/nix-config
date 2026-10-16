{
  config.substrate.modules.programs.ffmpeg = {
    provides = [ "video:production" ];
    tags = [ "video:production" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.stable.ffmpeg-full ];
      };
  };
}
