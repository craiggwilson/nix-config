{ lib, inputs, pkgs, stdenv, ...}:

stdenv.mkDerivation {
    name = "atlas-cli";
    version = "1.12.1";

    src = pkgs.fetchzip {
        url = "https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.12.1_linux_x86_64.tar.gz";
        hash = "sha256-o8IYxhlk8agaIgIZgkn9rI/wT6ZtnnCEAmJOJuOwpbQ=";
    };

    meta = {
        mainProgram = "atlas";
    };

    installPhase = ''
        mkdir -p $out/bin
        cp $src/bin/atlas $out/bin/atlas
    '';
}
