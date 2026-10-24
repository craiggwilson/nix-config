{
  substrate.packages.mail-filters =
    { pkgs, ... }:
    pkgs.runCommand "mail-filters"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta = {
          description = "Declarative mail filter management: Gmail sync via gws, Fastmail Sieve render";
          mainProgram = "mail-filters";
        };
      }
      ''
        install -Dm755 ${./mail-filters/mail-filters.py} $out/bin/mail-filters
        wrapProgram $out/bin/mail-filters \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.python3 ]}
      '';
}
