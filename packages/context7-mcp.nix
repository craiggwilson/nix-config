{ lib, pkgs, ... }:
let
  version = "0.5.3";
  rev = "9256fdfb9c136f54430f82952e6cccdf1eb501d4";

  src = pkgs.fetchFromGitHub {
    owner = "upstash";
    repo = "context7";
    inherit rev;
    hash = "sha256-J3FS0HPpkuriuxEyY1dluwdMovdvgWUTFgBxVUlf+GA=";
  };

  # Fixed-output derivation for dependencies.
  # Installs from the monorepo root so that workspace resolution and the root
  # tsconfig.json (extended by packages/mcp/tsconfig.json) are available.
  deps = pkgs.stdenv.mkDerivation {
    pname = "context7-mcp-deps";
    inherit version src;

    nativeBuildInputs = [ pkgs.bun ];

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      export HOME=$TMPDIR

      # Install from monorepo root so workspace packages resolve correctly
      bun install --no-cache

      mkdir -p $out
      cp -r node_modules $out/
      cp -r packages/mcp/node_modules $out/mcp-node_modules 2>/dev/null || true
      cp pnpm-lock.yaml package.json $out/
    '';

    outputHash = "sha256-YkxnV4j/mh1intfKJqRCASVDL7PvqC11naMTb0F4vU8=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "context7-mcp";
  inherit version src;

  nativeBuildInputs = [
    pkgs.nodejs
    pkgs.makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    # Set up node_modules from the deps FOD
    cp -r ${deps}/node_modules .
    chmod -R u+w node_modules

    # Place the mcp package's own deps where tsc can find them
    cp -r ${deps}/mcp-node_modules packages/mcp/node_modules
    chmod -R u+w packages/mcp/node_modules

    # Patch shebangs that reference /usr/bin/env (not available in sandbox)
    substituteInPlace node_modules/.bin/tsc \
      --replace-fail "/usr/bin/env node" "${pkgs.nodejs}/bin/node"

    # Compile TypeScript using the tsc from node_modules
    node_modules/.bin/tsc --project packages/mcp/tsconfig.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/context7-mcp

    # Recreate the monorepo layout so bun's relative symlinks resolve correctly:
    #   $out/lib/context7-mcp/node_modules/.bun/...   (root bun cache)
    #   $out/lib/context7-mcp/packages/mcp/node_modules -> ../../../node_modules/.bun/...
    mkdir -p $out/lib/context7-mcp/packages/mcp

    cp -r node_modules $out/lib/context7-mcp/node_modules
    cp -r packages/mcp/node_modules $out/lib/context7-mcp/packages/mcp/node_modules
    cp -r packages/mcp/dist $out/lib/context7-mcp/packages/mcp/dist
    cp packages/mcp/package.json $out/lib/context7-mcp/packages/mcp/package.json

    chmod +x $out/lib/context7-mcp/packages/mcp/dist/index.js

    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/context7-mcp \
      --add-flags $out/lib/context7-mcp/packages/mcp/dist/index.js \
      --chdir $out/lib/context7-mcp/packages/mcp

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
