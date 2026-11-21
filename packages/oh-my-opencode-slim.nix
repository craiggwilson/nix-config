{
  substrate.packages.oh-my-opencode-slim =
    { lib, pkgs, ... }:
    let
      pname = "oh-my-opencode-slim";
      rev = "d667451c304b5049b5c4b1c1e5498e851e94fce2";
      version = "3.0.7-unstable-${lib.substring 0 7 rev}";

      src = pkgs.fetchFromGitHub {
        owner = "alvinunreal";
        repo = "oh-my-opencode-slim";
        inherit rev;
        hash = "sha256-uh9v1/lSi8WOxSezGR6bOGUJoLWQhG5DWRkLcjXRtWg=";
      };

      # Keep the network-dependent installs in a fixed-output derivation. The
      # build needs devDependencies; only production dependencies are shipped.
      deps = pkgs.stdenvNoCC.mkDerivation {
        pname = "${pname}-deps";
        inherit version src;

        nativeBuildInputs = [ pkgs.bun ];

        dontConfigure = true;
        dontFixup = true;

        buildPhase = ''
          runHook preBuild
          export HOME="$TMPDIR"
          export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"
          bun install --frozen-lockfile --ignore-scripts --backend=copyfile
          mv node_modules "$TMPDIR/build-node_modules"
          bun install --frozen-lockfile --production --ignore-scripts --backend=copyfile
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp -R "$TMPDIR/build-node_modules" "$out/build-node_modules"
          cp -R node_modules "$out/node_modules"
          runHook postInstall
        '';

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        # Re-pin when the nixpkgs Bun version changes its node_modules layout.
        outputHash = "sha256-7GlQMCY1WkEX8wiyXFtLFrVkn9vchud7Q82gDwq8Alg=";
      };
    in
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version src;

      nativeBuildInputs = [
        pkgs.bun
        pkgs.nodejs
      ];

      dontConfigure = true;
      dontFixup = true;

      buildPhase = ''
        runHook preBuild
        export HOME="$TMPDIR"
        cp -R ${deps}/build-node_modules node_modules
        chmod -R u+w node_modules
        substituteInPlace node_modules/.bin/tsc \
          --replace-fail "/usr/bin/env node" "${pkgs.nodejs}/bin/node"
        bun run build
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        pluginDir=$out/lib/node_modules/oh-my-opencode-slim
        mkdir -p "$pluginDir/src/companion"
        cp -R dist "$pluginDir/dist"
        cp -R src/skills "$pluginDir/src/skills"
        cp src/companion/companion-manifest.json "$pluginDir/src/companion/"
        cp package.json oh-my-opencode-slim.schema.json LICENSE \
          README.md README.zh-CN.md README.ja-JP.md README.ko-KR.md README.fa-IR.md \
          "$pluginDir/"
        cp -R ${deps}/node_modules "$pluginDir/node_modules"
        runHook postInstall
      '';

      passthru = {
        inherit deps;
      };

      meta = {
        description = "Lightweight agent orchestration plugin for OpenCode";
        homepage = "https://github.com/alvinunreal/oh-my-opencode-slim";
        license = lib.licenses.mit;
        platforms = lib.platforms.unix;
      };
    };
}
