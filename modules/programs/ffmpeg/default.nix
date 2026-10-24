{
  config.substrate.modules.programs.ffmpeg = {
    tags = [ "role:video-production" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.stable.ffmpeg-full ];
      };
  };
}
