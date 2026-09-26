{
  config.substrate.modules.programs.lilypond = {
    tags = [ "users:craig:personal" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.lilypond ];
      };
  };
}
