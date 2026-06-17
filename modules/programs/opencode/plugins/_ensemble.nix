{ lib, pkgs, ... }:
let
  version = "0.15.0";

  src = pkgs.fetchFromGitHub {
    owner = "hueyexe";
    repo = "opencode-ensemble";
    tag = "v${version}";
    hash = "sha256-eTdwru0Fw9i5/N6tz7pRZiTNeUnF8j1muuMbG4ebg/s=";
  };

  deps = pkgs.stdenv.mkDerivation {
    pname = "opencode-ensemble-deps";
    inherit version src;

    nativeBuildInputs = [ pkgs.bun ];

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      export HOME=$TMPDIR

      # --ignore-scripts keeps the fixed-output fetch focused on dependency materialization.
      bun install --no-cache --ignore-scripts

      mkdir -p $out
      cp -r node_modules $out/
      cp bun.lock package.json $out/
    '';

    outputHash = "sha256-28TloesVmt46x4lmf7YXV/kzeXuWyQGju8i1WqpXLJc=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-ensemble";
  inherit version src;

  nativeBuildInputs = [ pkgs.bun ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    cp -r ${deps}/node_modules .
    cp ${deps}/bun.lock .

    bun build src/index.ts --outdir dist --target bun --format esm

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/opencode-ensemble

    cp -r dist $out/lib/opencode-ensemble/
    cp package.json $out/lib/opencode-ensemble/

    runHook postInstall
  '';

  passthru = {
    inherit deps;
    pluginDir = "${placeholder "out"}/lib/opencode-ensemble";
  };

  meta = {
    description = "Parallel agent teams plugin for OpenCode";
    homepage = "https://github.com/hueyexe/opencode-ensemble";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
