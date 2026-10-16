{
  config.substrate.modules.programs.lilypond = {
    provides = [ "profiles:personal" ];
    tags = [ "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lilypond ];
      };
  };
}
