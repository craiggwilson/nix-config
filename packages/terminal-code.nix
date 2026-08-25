{
  lib,
  pkgs,
  ...
}:
let
  name = "terminal-code";
  version = "0.2.0";
  codeServerVersion = "4.132.0";

  # Hashes are the ones upstream publishes in its installer (tode.sh/install)
  # and pins in src/codeserver/vendored.ts, so we ship exactly what tode
  # expects instead of letting it download into $HOME on first run.
  src = pkgs.fetchurl {
    url = "https://tode-releases.zenbu-labs.workers.dev/dl/stable/v${version}/tode-linux-x64.tar.gz";
    hash = "sha256-g+pW/SovwCr2oZ6X02EAipr4U4gjETDgN/bnP0rIMfs=";
  };

  codeServerSrc = pkgs.fetchurl {
    url = "https://github.com/coder/code-server/releases/download/v${codeServerVersion}/code-server-${codeServerVersion}-linux-amd64.tar.gz";
    hash = "sha256-o40m9MuB92j+3f954pN/0/Ocg9Pai+PaciXhCH5i5O0=";
  };
in
pkgs.stdenv.mkDerivation {
  inherit name version src;

  # tode ships a prebuilt Electron tree (terminal-browser) and code-server's
  # node binary; patch them against our library set.
  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  # Only wanted by code-server's optional Microsoft-auth extension helper;
  # leave it unpatched rather than pulling in all of webkitgtk.
  autoPatchelfIgnoreMissingDeps = [
    "libwebkit2gtk-4.1.so.0"
    "libsoup-3.0.so.0"
    "libsecret-1.so.0"
  ];

  buildInputs = [
    pkgs.alsa-lib
    pkgs.at-spi2-atk
    pkgs.cairo
    pkgs.cups
    pkgs.glib
    pkgs.gtk3
    pkgs.libdrm
    pkgs.libxkbcommon
    pkgs.mesa
    pkgs.nspr
    pkgs.nss
    pkgs.pango
    pkgs.systemd
    pkgs.libx11
    pkgs.libxcomposite
    pkgs.libxdamage
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxrandr
    pkgs.libxcb
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/terminal-code $out/bin
    tar -xzf $src -C $out/share/terminal-code --strip-components 1
    mkdir -p $out/share/terminal-code/code-server
    tar -xzf ${codeServerSrc} -C $out/share/terminal-code/code-server --strip-components 1

    # tode rewrites this launcher inside its install root on every start
    # (release.js writeLauncher), which is impossible on a read-only store.
    # Pre-create the identical script and point TODE_TERMINAL_BROWSER_BIN at
    # it, which makes resolveRuntime() take its no-write override path.
    mkdir -p $out/share/terminal-code/vendor/terminal-browser/bin
    cat > $out/share/terminal-code/vendor/terminal-browser/bin/terminal-browser <<'EOF'
    #!/bin/sh
    ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
    export TERMINAL_BROWSER_DIST_ROOT="$ROOT"
    export ELECTRON_RUN_AS_NODE=1
    export XDG_DATA_HOME="''${TODE_BROWSER_DATA:-$HOME/.local/share/tode/browser/share}"
    export XDG_STATE_HOME="''${TODE_BROWSER_STATE:-$HOME/.local/state/tode/browser/state}"
    export XDG_CACHE_HOME="''${TODE_BROWSER_CACHE:-$HOME/.cache/tode/browser}"
    export TERMINAL_BROWSER_APPDATA="''${TODE_BROWSER_APPDATA:-$HOME/.local/share/tode/browser/chromium}"
    exec "$ROOT/electron/electron" "$ROOT/cli/dist/main.js" "$@"
    EOF
    chmod +x $out/share/terminal-code/vendor/terminal-browser/bin/terminal-browser

    cat > $out/bin/tode <<EOF
    #!/bin/sh
    export TODE_INSTALL_ROOT="$out/share/terminal-code"
    export TODE_TERMINAL_BROWSER_BIN="$out/share/terminal-code/vendor/terminal-browser/bin/terminal-browser"
    export TODE_CODE_SERVER="$out/share/terminal-code/code-server/bin/code-server"
    export ELECTRON_RUN_AS_NODE=1
    exec "$out/share/terminal-code/vendor/terminal-browser/electron/electron" \
      "$out/share/terminal-code/dist/main.js" "\$@"
    EOF
    chmod +x $out/bin/tode

    runHook postInstall
  '';

  meta = {
    description = "VS Code in the terminal";
    homepage = "https://github.com/zenbu-labs/terminal-code";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "tode";
  };
}
