{
  config.substrate.modules.programs.ffmpeg = {
    tags = [ "video:production" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.stable.ffmpeg-full ];
      };
  };
}

