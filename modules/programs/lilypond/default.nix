{
  config.substrate.modules.programs.lilypond = {
    tags = [ "profile:music-notation" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lilypond ];
      };
  };
}
