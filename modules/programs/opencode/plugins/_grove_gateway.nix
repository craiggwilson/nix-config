{ lib, pkgs, ... }:
let
  version = "1.3.0";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/10gen/grove-gateway-opencode-plugin";
    ref = "v${version}";
    rev = "7693be3bd1140a3d789a863bec4bd32c9bf58c60";
  };

  deps = pkgs.stdenv.mkDerivation {
    pname = "grove-gateway-opencode-plugin-deps";
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

    outputHash = "sha256-yXWkbEGDMINHxDL65MIiohFzskA6ZmcyZznIjoJJ/zk=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "grove-gateway-opencode-plugin";
  inherit version src;

  nativeBuildInputs = [ pkgs.bun ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR

    cp -r ${deps}/node_modules .
    cp ${deps}/bun.lock .

    bun build src/index.ts --bundle --target bun --outfile dist/grove-gateway.js

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/grove-gateway-opencode-plugin

    cp -r dist $out/lib/grove-gateway-opencode-plugin/
    cp package.json $out/lib/grove-gateway-opencode-plugin/

    runHook postInstall
  '';

  passthru = {
    inherit deps;
    pluginDir = "${placeholder "out"}/lib/grove-gateway-opencode-plugin";
  };

  meta = {
    description = "OpenCode plugin for MongoDB's Grove AI Gateway";
    homepage = "https://github.com/10gen/grove-gateway-opencode-plugin";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
