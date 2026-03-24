{ lib, pkgs, ... }:
let
  version = "0.8.3";

  src = pkgs.fetchFromGitHub {
    owner = "alvinunreal";
    repo = "oh-my-opencode-slim";
    tag = "v${version}";
    hash = "sha256-ftRtXNnuEJvzNgSHR37X9ggwWMRTbZIFc0VOm4Hd4XE=";
  };

  # Fixed-output derivation for npm dependencies
  deps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-opencode-slim-deps";
    inherit version src;

    nativeBuildInputs = [ pkgs.bun ];

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      export HOME=$TMPDIR

      bun install --frozen-lockfile --no-cache

      mkdir -p $out
      cp -r node_modules $out/
      cp bun.lock package.json $out/
    '';

    outputHash = "sha256-Y0nL6hFc8H+yG8w3gDrG6MohOXhxQrqRp9dKYXQj0jU=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "oh-my-opencode-slim";
  inherit version src;

  nativeBuildInputs = [ pkgs.bun ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    cp -r ${deps}/node_modules .
    cp ${deps}/bun.lock .

    # Build main entry point and CLI entry point
    bun build src/index.ts --outdir dist --target bun --format esm
    bun build src/cli/index.ts --outdir dist/cli --target bun --format esm

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/oh-my-opencode-slim

    cp -r dist $out/lib/oh-my-opencode-slim/
    cp package.json $out/lib/oh-my-opencode-slim/

    runHook postInstall
  '';

  passthru = {
    inherit deps;
    # The directory opencode should point to as the plugin path
    pluginDir = "${placeholder "out"}/lib/oh-my-opencode-slim";
  };

  meta = {
    description = "Slimmed, cleaned and fine-tuned oh-my-opencode fork for OpenCode";
    homepage = "https://github.com/alvinunreal/oh-my-opencode-slim";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
