{ lib, pkgs, ... }:
let
  name = "auggie";
  version = "0.27.2";
in
pkgs.stdenv.mkDerivation {
  inherit name version;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@augmentcode/${name}/-/${name}-${version}.tgz";
    hash = "sha256-kBn0ghkevIh/yfnaymo5Gbh1JtrwWFEO7QUnNQCEKgM=";
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
