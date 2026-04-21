{ lib, pkgs, ... }:
let
  version = "3.17.4";

  src = pkgs.fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "oh-my-openagent";
    tag = "v${version}";
    hash = "sha256-2z+HDMP5SeUcN3tI4uDqwoqvmA0fdXbhSCMOFYnumIA=";
  };

  # Fixed-output derivation for npm dependencies
  deps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent-deps";
    inherit version src;

    nativeBuildInputs = [ pkgs.bun ];

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      export HOME=$TMPDIR

      # --ignore-scripts prevents postinstall/prepare from running during the
      # FOD fetch; the actual build happens in the main derivation below.
      bun install --no-cache --ignore-scripts

      mkdir -p $out
      cp -r node_modules $out/
      cp bun.lock package.json $out/
    '';

    outputHash = "sha256-C+/5eehlK23Ts8HCluCWYetVQX3kbJY5OhnSLueqyFY=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "oh-my-openagent";
  inherit version src;

  nativeBuildInputs = [ pkgs.bun ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    cp -r ${deps}/node_modules .
    cp ${deps}/bun.lock .

    # Build main entry point and CLI entry point; @ast-grep/napi is a native
    # module loaded at runtime — mark it external so bun does not try to bundle it.
    bun build src/index.ts --outdir dist --target bun --format esm --external @ast-grep/napi
    bun build src/cli/index.ts --outdir dist/cli --target bun --format esm --external @ast-grep/napi

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/oh-my-openagent

    cp -r dist $out/lib/oh-my-openagent/
    cp package.json $out/lib/oh-my-openagent/

    runHook postInstall
  '';

  passthru = {
    inherit deps;
    # The directory opencode should point to as the plugin path
    pluginDir = "${placeholder "out"}/lib/oh-my-openagent";
  };

  meta = {
    description = "Multi-agent orchestration plugin for OpenCode";
    homepage = "https://github.com/code-yeongyu/oh-my-openagent";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
