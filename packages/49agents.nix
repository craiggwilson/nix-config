{ lib, pkgs, ... }:
let
  version = "0.2.2";
  rev = "699ed08ddce6ccb8e7d01e0e996e350d86ad1922";

  src = pkgs.fetchFromGitHub {
    owner = "alpbahadur";
    repo = "49Agents";
    inherit rev;
    hash = "sha256-S4qMEf23Zxa0iMnT2bV8tMbZW+AvON7jpf+0yVcjH9E=";
  };

  runtimePath = lib.makeBinPath [
    pkgs.nodejs_22
    pkgs.tmux
    pkgs.ttyd
    pkgs.lsof
    pkgs.procps
  ];

  # Fixed-output derivation fetching the npm dependency tree. Install scripts
  # are skipped so the output never contains compiled binaries or toolchain
  # paths (those are built in the main derivation below); this keeps the FOD
  # free of store references.
  mkNpmDeps =
    {
      pname,
      subdir,
      installCmd,
      hash,
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname version src;

      nativeBuildInputs = [
        pkgs.nodejs_22
        # Referenced from the installPhase below; declaring it here keeps the
        # fixed-output derivation free of undeclared store references.
        pkgs.cacert
      ];

      dontBuild = true;
      dontFixup = true;

      installPhase = ''
        # The host nix setup leaves these pointed at a nonexistent file, which
        # breaks TLS verification for every npm request.
        export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        export NIX_SSL_CERT_FILE=$SSL_CERT_FILE
        export HOME=$TMPDIR

        cd ${subdir}

        # The local resolver intermittently drops lookups (EAI_AGAIN) and npm
        # does not retry DNS failures; give it three attempts.
        attempt=0
        until ${installCmd}; do
          attempt=$((attempt + 1))
          if [ $attempt -ge 3 ]; then
            echo "install failed after $attempt attempts"
            exit 1
          fi
          echo "retrying install (attempt $attempt)"
          rm -rf node_modules
          sleep 5
        done

        mkdir $out
        cp -r node_modules $out/
      '';

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
    };

  cloudDeps = mkNpmDeps {
    pname = "49agents-cloud-deps";
    subdir = "cloud";
    # devDeps are needed: build.js uses esbuild/terser/javascript-obfuscator
    installCmd = "npm ci --ignore-scripts --no-audit --no-fund";
    hash = "sha256-SZeAIyTt9dB20iXxO1zQefTC4VKmvJJcS3pchmmvS4s=";
  };

  agentDeps = mkNpmDeps {
    pname = "49agents-agent-deps";
    subdir = "agent";
    installCmd = "npm install --no-audit --no-fund";
    hash = "sha256-N9oDUPD6kdg8vrz8+HvY8bLui2GUoH76wl/bRTJA/mg=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "49agents";
  inherit version src;

  nativeBuildInputs = [
    pkgs.nodejs_22
    pkgs.python3
    pkgs.makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    export npm_config_nodedir=${pkgs.nodejs_22}

    cp -r ${cloudDeps}/node_modules cloud/node_modules
    chmod -R u+w cloud/node_modules

    # Compile the native better-sqlite3 addon here rather than in the deps
    # FOD, so its runpath may legally reference store paths.
    (cd cloud && npm rebuild --offline --no-audit --no-fund)

    cp -r ${agentDeps}/node_modules agent/node_modules
    chmod -R u+w agent/node_modules

    # Bundle client assets into cloud/public/
    (cd cloud && node build.js)

    # Server runs from source; devDependencies are only for building assets.
    (cd cloud && npm prune --omit=dev --no-audit --no-fund)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    share=$out/share/49agents
    mkdir -p $share $out/bin

    cp -r . $share

    # Ship the agent download tarball so ensureAgentTarball never tries to
    # write into the read-only store path at server startup.
    mkdir -p $share/cloud/dl
    tar czf $share/cloud/dl/49-agent.tar.gz -C $share agent/

    substituteInPlace $share/49ctl \
      --replace-fail 'STATE_DIR="$SCRIPT_DIR/.49agents"' 'STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/49agents"'

    # Appending to .gitignore would fail on the read-only store path.
    sed -i '/── Add \.49agents to \.gitignore/,/^fi$/d' $share/49ctl

    # The database must live outside the store; DATABASE_PATH is respected by
    # the server (default is relative to the process cwd).
    substituteInPlace $share/49ctl \
      --replace-fail 'CLOUD_DB_FILE="$SCRIPT_DIR/cloud/data/tc.db"' 'CLOUD_DB_FILE="$STATE_DIR/tc.db"' \
      --replace-fail 'PORT="$CLOUD_PORT" nohup node' 'DATABASE_PATH="$CLOUD_DB_FILE" PORT="$CLOUD_PORT" nohup node'

    # Assets are prebuilt above; never run npm against the store path.
    # Neutralize the two call sites (setup + build command) rather than
    # rewriting the function, which upstream may reshape arbitrarily.
    sed -i \
      -e 's/^  cmd_build$/  echo "Assets are prebuilt by nix; skipping install."/' \
      -e 's/cmd_build ;;/true ;;/' \
      $share/49ctl

    # Offline/local mode for everything 49ctl spawns (cloud + agent): pair
    # with the local dev identity, no browser sign-in required. HOST must be
    # pinned because SKIP_CLOUD_AUTH flips upstream's default bind to 0.0.0.0.
    makeWrapper $share/49ctl $out/bin/49ctl \
      --prefix PATH : ${runtimePath} \
      --set SKIP_CLOUD_AUTH 1 \
      --set HOST 127.0.0.1

    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/49-agent \
      --add-flags $share/agent/bin/49-agent.js \
      --prefix PATH : ${runtimePath} \
      --set SKIP_CLOUD_AUTH 1

    runHook postInstall
  '';

  passthru = {
    inherit cloudDeps agentDeps;
  };

  meta = {
    description = "Self-hosted 2D IDE for managing AI agents across terminals, projects, and machines";
    homepage = "https://github.com/alpbahadur/49Agents";
    license = lib.licenses.unfree; # BSL 1.1
    mainProgram = "49ctl";
    platforms = lib.platforms.linux;
  };
}
