{
  config.substrate.modules.programs.ffmpeg = {
    tags = [ "video:production" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.stable.ffmpeg-full ];
      };
  };
}

