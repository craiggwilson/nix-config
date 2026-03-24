{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation {
  pname = "opencode-engram-plugin";
  version = "0.1.0";

  src = ./opencode-engram-plugin;

  nativeBuildInputs = [ pkgs.bun ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    bun build index.ts --outdir dist --target bun --format esm
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/opencode-engram-plugin
    cp dist/index.js $out/lib/opencode-engram-plugin/
    cat > $out/lib/opencode-engram-plugin/package.json <<EOF
    {
      "name": "opencode-engram-plugin",
      "version": "0.1.0",
      "type": "module",
      "main": "index.js"
    }
    EOF
    runHook postInstall
  '';

  meta = {
    description = "OpenCode plugin providing memory search and add tools via engram";
    platforms = lib.platforms.linux;
  };
}
