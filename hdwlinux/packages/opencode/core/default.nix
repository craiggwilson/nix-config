{ lib, pkgs, ... }:
let
  version = "0.1.0";

  # Build the shared core library with TypeScript, using the workspace-level
  # build output from the parent opencode package.
  workspace = pkgs.callPackage ../. { };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-planner-core";
  inherit version;

  src = workspace.opencode-plugins-suite;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-planner-core
    mkdir -p $out/share/doc/opencode-planner-core

    cd core

    # Install built artefacts and metadata as a consumable Node module
    cp -r dist package.json $out/lib/node_modules/opencode-planner-core/
    if [ -d node_modules ]; then cp -r node_modules $out/lib/node_modules/opencode-planner-core/; fi

    # Documentation
    if [ -f AGENTS.md ]; then cp AGENTS.md $out/share/doc/opencode-planner-core/; fi

    runHook postInstall
  '';

  meta = {
    description = "OpenCode Planner Core - Shared utilities for planning plugins";
    homepage = "https://github.com/craiggwilson/nix-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
