{
  config.substrate.modules.programs.lilypond = {
    tags = [ "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lilypond ];
      };
  };
}
