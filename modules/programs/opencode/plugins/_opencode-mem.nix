{ lib, pkgs, ... }:
let
  version = "2.24.3";

  tarball = pkgs.fetchurl {
    url = "https://registry.npmjs.org/opencode-mem/-/opencode-mem-${version}.tgz";
    hash = "sha256-jCzN9hkkErfh0g25veld6OhEQ5l8mu4tH9wbWVSLj14=";
  };

  deps = pkgs.stdenv.mkDerivation {
    pname = "opencode-mem-deps";
    inherit version;

    src = pkgs.runCommand "opencode-mem-pkg-json" { } ''
      mkdir -p $out
      tar xzf ${tarball} --strip-components=1 -C $out
    '';

    nativeBuildInputs = [ pkgs.bun ];

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      export HOME=$TMPDIR
      bun install --no-cache --ignore-scripts
      mkdir -p $out
      cp -r node_modules $out/
      cp package.json $out/
    '';

    outputHash = "sha256-c8PY7ogF0K2tIORGlJoVGjUMdeonNYZaH6jmpUuragc=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-mem";
  inherit version;

  src = pkgs.runCommand "opencode-mem-extracted" { } ''
    mkdir -p $out
    tar xzf ${tarball} --strip-components=1 -C $out
  '';

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/opencode-mem
    cp -r $src/dist $out/lib/opencode-mem/
    cp $src/package.json $out/lib/opencode-mem/
    cp -r ${deps}/node_modules $out/lib/opencode-mem/

    # Drop musl-only sharp binaries — we're on glibc
    chmod -R u+w $out/lib/opencode-mem/node_modules/@img
    rm -rf $out/lib/opencode-mem/node_modules/@img/sharp-linuxmusl-x64
    rm -rf $out/lib/opencode-mem/node_modules/@img/sharp-libvips-linuxmusl-x64

    runHook postInstall
  '';

  passthru = {
    inherit deps;
    pluginDir = "${placeholder "out"}/lib/opencode-mem";
  };

  meta = {
    description = "OpenCode plugin for persistent memory using local Turso/libSQL vector search";
    homepage = "https://github.com/tickernelz/opencode-mem";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
