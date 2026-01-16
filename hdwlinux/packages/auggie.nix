{ lib, pkgs, ... }:
let
  name = "auggie";
  version = "0.14.0";
in
pkgs.stdenv.mkDerivation {
  inherit name version;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@augmentcode/${name}/-/${name}-${version}.tgz";
    hash = "sha256-z5nhpKB+ToRgEMnEQVuLR0z8ZK96i4mq8K0QxZAbBnI=";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/${name}
    cp -r . $out/share/${name}
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/auggie \
      --add-flags $out/share/${name}/augment.mjs
    runHook postInstall
  '';

  meta = {
    description = "AI agent that brings the power of Augment's agent and context engine into your terminal";
    homepage = "https://docs.augmentcode.com/cli";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    mainProgram = "auggie";
  };
}
