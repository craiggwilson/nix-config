{
  config.substrate.modules.programs.ffmpeg = {
    provides = [
      "programs:ffmpeg"
      "video:production"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.stable.ffmpeg-full ];
      };
  };
}
