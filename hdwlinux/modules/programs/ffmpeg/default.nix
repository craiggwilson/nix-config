{
  config.substrate.modules.programs.ffmpeg = {
    tags = [ "video:production" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ffmpeg-full ];
      };
  };
}

