{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "atlas-cli";
  version = "1.54.0";

  src = pkgs.fetchzip {
    url = "https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.54.0_linux_x86_64.tar.gz";
    hash = "sha256-iAQJGNJclFAEH8mjUWw1JR0guSPO+bKul93B7dRPDkE=";
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
}
