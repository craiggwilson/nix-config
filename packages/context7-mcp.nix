{ lib, pkgs, ... }:
let
  version = "1.0.30";

  src = pkgs.fetchFromGitHub {
    owner = "upstash";
    repo = "context7";
    tag = "v${version}";
    hash = "sha256-cNm/NROFHy+3cOozzvC1WUhGb7bwccvOIiMt30lAN3E=";
  };

  # Step 1: Fixed-output derivation for dependencies
  deps = pkgs.stdenv.mkDerivation {
    pname = "context7-mcp-deps";
    inherit version src;

    nativeBuildInputs = [ pkgs.bun ];

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      export HOME=$TMPDIR

      # Install dependencies
      bun install --frozen-lockfile --no-cache

      # Copy to output
      mkdir -p $out
      cp -r node_modules $out/
      cp bun.lock package.json $out/
    '';

    # This hash represents the dependencies
    outputHash = "sha256-rSz+BVSnyTP5tE/j3mlijvIpyMF0QIIouFxYv4Y5lRU=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "context7-mcp";
  inherit version src;

  nativeBuildInputs = [
    pkgs.bun
    pkgs.makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    cp -r ${deps}/node_modules .
    cp ${deps}/bun.lock .

    substituteInPlace node_modules/.bin/tsc \
      --replace-fail "/usr/bin/env node" "${lib.getExe pkgs.nodejs}"

    bun run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/context7-mcp

    cp -r dist $out/lib/context7-mcp/

    cp -r node_modules $out/lib/context7-mcp/
    cp package.json $out/lib/context7-mcp/

    chmod +x $out/lib/context7-mcp/dist/index.js

    mkdir -p $out/bin
    makeWrapper $out/lib/context7-mcp/dist/index.js $out/bin/context7-mcp \
      --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs ]} \

    runHook postInstall
  '';

  passthru = {
    inherit deps;
  };

  meta = {
    description = "Up-to-date code documentation for LLMs and AI code editors";
    homepage = "https://context7.com";
    license = lib.licenses.mit;
    mainProgram = "context7-mcp";
  };
}
