{ lib, pkgs, ... }:
let
  version = "0.2.10";

  src = pkgs.fetchFromGitHub {
    owner = "antongulin";
    repo = "opencode-skill-creator";
    tag = "v${version}";
    hash = "sha256-N/DyGkvB96c5qdcibDB64LNIdvTWbM2fh3PHl5mU+48=";
  };

  deps = pkgs.stdenv.mkDerivation {
    pname = "opencode-skill-creator-deps";
    inherit version src;

    nativeBuildInputs = [ pkgs.bun ];

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      export HOME=$TMPDIR

      cd plugin
      cp package.json package.json.orig
      ${pkgs.jq}/bin/jq '. + {dependencies: {"@opencode-ai/plugin": "^1.0.0"}}' package.json.orig > package.json

      bun install --no-cache --ignore-scripts

      mkdir -p $out
      cp -r node_modules $out/
      cp bun.lock package.json $out/
    '';

    outputHash = "sha256-/h3Fi3SjnmBMDHmIzQWLNdGjcLbu2sdmBOcEkz8B5eA=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-skill-creator";
  inherit version src;

  nativeBuildInputs = [ pkgs.bun ];

  dontFixup = true;

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    cd plugin
    cp -r ${deps}/node_modules .
    cp ${deps}/bun.lock .
    bun build skill-creator.ts --outfile dist/index.js --target bun --format esm

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/opencode-skill-creator

    cp -r dist $out/lib/opencode-skill-creator/
    cp -r bin $out/lib/opencode-skill-creator/
    cp -r lib $out/lib/opencode-skill-creator/
    cp -r skill $out/lib/opencode-skill-creator/
    cp -r templates $out/lib/opencode-skill-creator/
    cp README.md $out/lib/opencode-skill-creator/
    cp package.json $out/lib/opencode-skill-creator/
    substituteInPlace $out/lib/opencode-skill-creator/package.json \
      --replace '"main": "./skill-creator.ts"' '"main": "./dist/index.js"'

    runHook postInstall
  '';

  passthru = {
    inherit deps;
    pluginDir = "${placeholder "out"}/lib/opencode-skill-creator";
  };

  meta = {
    description = "OpenCode plugin for skill creation and optimization";
    homepage = "https://github.com/antongulin/opencode-skill-creator";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
