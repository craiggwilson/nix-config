{
  substrate.packages.atlas-cli =
    { pkgs, ... }:
    pkgs.stdenv.mkDerivation {
      name = "atlas-cli";
      version = "1.59.4";

      src = pkgs.fetchzip {
        url = "https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.59.4_linux_x86_64.tar.gz";
        # Upstream repacked this tarball in place (S3 etag v4, 2026-10-29);
        # version-pinned URL, content drift expected occasionally.
        hash = "sha256-XWUsnoNBLtuQ7cCy4GzaOq265bVw5BkmcjTdVtsuyAo=";
      };

      installPhase = ''
        mkdir -p $out/bin
        cp $src/bin/atlas $out/bin/atlas
      '';

      meta = {
        mainProgram = "atlas";
        description = "MongoDB Atlas CLI";
        platforms = [ "x86_64-linux" ];
      };
    };
}
