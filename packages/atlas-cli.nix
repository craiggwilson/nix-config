{
  substrate.packages.atlas-cli =
    { pkgs, ... }:
    pkgs.stdenv.mkDerivation {
      name = "atlas-cli";
      version = "1.59.3";

      src = pkgs.fetchzip {
        url = "https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.59.3_linux_x86_64.tar.gz";
        hash = "sha256-678upM9lqqi2Bcf2LeeJ6vhTNdA3FDEyjbvZErSVphU=";
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
