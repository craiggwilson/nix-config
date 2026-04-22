{ lib, pkgs, ... }:
let
  name = "mato";
  version = "0.9.5";
in
pkgs.stdenv.mkDerivation {
  inherit name version;

  src = pkgs.fetchurl {
    url = "https://github.com/mr-kelly/mato/releases/download/v${version}/mato-linux-x86_64-v${version}.tar.gz";
    hash = "sha256-PQwoCzJF82Lu5kG7WRH5i9Lxm2l4IDxrPeC/6pmq17Q=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar xzf $src -C $out/bin
    runHook postInstall
  '';

  meta = {
    description = "Multi-Agent Terminal Office - terminal multiplexer for managing AI agent swarms";
    homepage = "https://github.com/mr-kelly/mato";
    license = lib.licenses.mit;
    mainProgram = "mato";
    platforms = [ "x86_64-linux" ];
  };
}
