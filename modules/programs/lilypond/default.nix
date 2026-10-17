{
  config.substrate.modules.programs.lilypond = {
    provides = [
      "programs:lilypond"
      "profiles:personal"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lilypond ];
      };
  };
}
