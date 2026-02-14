{
  lib,
  pkgs,
  opencode-planner-core,
  ...
}:
let
  version = "0.1.0";

  workspace = pkgs.callPackage ../. { };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-program-planner";
  inherit version;

  src = workspace.opencode-plugins-suite;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-program-planner
    mkdir -p $out/share/doc/opencode-program-planner

    cd program-planner

    # Install built artefacts and metadata as a consumable Node module
    cp -r dist package.json $out/lib/node_modules/opencode-program-planner/
    if [ -d node_modules ]; then cp -r node_modules $out/lib/node_modules/opencode-program-planner/; fi

    # Link to core at runtime via node resolution path
    ln -s ${opencode-planner-core}/lib/node_modules/opencode-planner-core \
      $out/lib/node_modules/opencode-program-planner/node_modules/opencode-planner-core

    # Documentation
    if [ -f AGENTS.md ]; then cp AGENTS.md $out/share/doc/opencode-program-planner/; fi

    runHook postInstall
  '';

  meta = {
    description = "OpenCode Program Planner - Long-term program planning plugin";
    homepage = "https://github.com/craiggwilson/nix-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
