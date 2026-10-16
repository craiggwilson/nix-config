{
  config.substrate.modules.programs.lilypond = {
    provides = [ "programs:lilypond" "profiles:personal" ];
    tags = [ "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lilypond ];
      };
  };
}
