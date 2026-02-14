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
  pname = "opencode-project-planner";
  inherit version;

  src = workspace.opencode-plugins-suite;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-project-planner
    mkdir -p $out/share/doc/opencode-project-planner

    cd project-planner

    cp -r dist package.json $out/lib/node_modules/opencode-project-planner/
    if [ -d node_modules ]; then cp -r node_modules $out/lib/node_modules/opencode-project-planner/; fi

    ln -s ${opencode-planner-core}/lib/node_modules/opencode-planner-core \
      $out/lib/node_modules/opencode-project-planner/node_modules/opencode-planner-core

    if [ -f AGENTS.md ]; then cp AGENTS.md $out/share/doc/opencode-project-planner/; fi

    runHook postInstall
  '';

  meta = {
    description = "OpenCode Project Planner - Project-level planning plugin";
    homepage = "https://hdwlinux/nix-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
