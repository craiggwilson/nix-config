{ lib, pkgs, ... }:
let
  version = "0.1.0";

  # Fixed-output derivation for dependencies
  deps = pkgs.stdenv.mkDerivation {
    pname = "opencode-projects-plugin-deps";
    inherit version;
    src = ./.;

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

    outputHash = "sha256-pPVt7EfDtIGfcfmUkyUfIdHdiVhVAWLoGuvPVGGEo90=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-projects-plugin";
  inherit version;
  src = ./.;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-projects

    cp -r src $out/lib/node_modules/opencode-projects/
    cp -r ${deps}/node_modules $out/lib/node_modules/opencode-projects/
    cp package.json tsconfig.json $out/lib/node_modules/opencode-projects/

    runHook postInstall
  '';

  passthru = {
    inherit deps;
  };

  meta = {
    description = "Project planning, tracking, and execution plugin for OpenCode with beads integration";
    homepage = "https://github.com/craiggwilson/nix-config";
    license = lib.licenses.mit;
  };
}
