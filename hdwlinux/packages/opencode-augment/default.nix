{ lib, pkgs, ... }:
pkgs.buildNpmPackage {
  pname = "opencode-augment";
  version = "0.1.0";

  src = ./.;

  npmDepsHash = "sha256-R3Krss1lxjhRVNmE0AL7buEEvqCRDZ9DInS9MXHLlIE=";

  makeCacheWritable = true;
  npmFlags = [ "--legacy-peer-deps" ];

  # Build phase
  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  # Install phase - install as an npm package
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@opencode/augment-provider

    # Copy built files
    cp -r dist $out/lib/node_modules/@opencode/augment-provider/
    cp package.json $out/lib/node_modules/@opencode/augment-provider/

    # Copy node_modules for runtime dependencies
    cp -r node_modules $out/lib/node_modules/@opencode/augment-provider/

    runHook postInstall
  '';

  # Skip tests for now - they require OpenCode server running
  doCheck = false;

  meta = {
    description = "OpenCode provider implementation using Augment AI SDK";
    homepage = "https://github.com/craiggwilson/nix-config";
    license = lib.licenses.mit;
    mainProgram = "opencode-augment";
  };
}
