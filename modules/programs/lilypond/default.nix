{
  config.substrate.modules.programs.lilypond = {
    tags = [ "profile:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lilypond ];
      };
  };
}
