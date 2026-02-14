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
  pname = "opencode-work-executor";
  inherit version;

  src = workspace.opencode-plugins-suite;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-work-executor
    mkdir -p $out/share/doc/opencode-work-executor

    cd work-executor

    cp -r dist package.json $out/lib/node_modules/opencode-work-executor/
    if [ -d node_modules ]; then cp -r node_modules $out/lib/node_modules/opencode-work-executor/; fi

    ln -s ${opencode-planner-core}/lib/node_modules/opencode-planner-core \
      $out/lib/node_modules/opencode-work-executor/node_modules/opencode-planner-core

    if [ -f AGENTS.md ]; then cp AGENTS.md $out/share/doc/opencode-work-executor/; fi

    runHook postInstall
  '';

  meta = {
    description = "OpenCode Work Executor - Work execution plugin with specialist subagents";
    homepage = "https://github.com/craiggwilson/nix-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
