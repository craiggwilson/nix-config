{
  substrate.packages.internal.slackcli =
    { lib, pkgs, ... }:
    let
      pname = "slackcli";
      version = "0.15.0";

      src = pkgs.fetchFromGitHub {
        owner = "shaharia-lab";
        repo = "slackcli";
        # The commit v0.15.0 tags, which is also the commit the security review
        # covered.
        rev = "ae88d3c77a911647f13c8c856863cfc162b1f3f4";
        hash = "sha256-+EKR6/sBGyejN+fzRrja6XRVw8f0c92ZFXouC0vZL8A=";
      };

      # `bun install` is the only step that needs the network, so it is isolated
      # in a fixed-output derivation and everything downstream builds offline.
      # bun.lock pins exact versions and integrity hashes, so the vendored tree
      # is reproducible despite reaching out.
      vendored = pkgs.stdenv.mkDerivation {
        name = "${pname}-vendor-${version}";

        inherit src;

        nativeBuildInputs = [ pkgs.bun ];

        dontConfigure = true;

        buildPhase = ''
          runHook preBuild
          # bun wants a writable HOME for its cache, which the sandbox lacks.
          export HOME="$TMPDIR"
          export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"
          bun install --frozen-lockfile --production --backend=copyfile
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp -r . $out
          runHook postInstall
        '';

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-Vhb5tuqEI+84hjNxM8XGXqE1bVJ00ct4yCoFCbznGS4=";
      };
    in
    pkgs.stdenv.mkDerivation rec {
      inherit pname version;

      src = vendored;

      nativeBuildInputs = [
        pkgs.bun
        pkgs.autoPatchelfHook
      ];

      # Only so autoPatchelf has a glibc to resolve the interpreter against.
      buildInputs = [ pkgs.stdenv.cc.cc.lib ];

      dontConfigure = true;

      # A Bun `--compile` binary carries its loader and entrypoint tables inside
      # the executable. Stripping it or letting patchelf shrink its RPATHs
      # rewrites those sections and the binary silently falls back to bun's own
      # CLI: it prints bun's help and reports bun's version, while still exiting
      # 0. autoPatchelfHook patches in postFixup, which runs after strip, so
      # patch explicitly at install time instead.
      dontStrip = true;
      dontPatchELF = true;

      # Upstream's own build script rather than a copy of its flags, so the
      # compile stays in sync with the project. It shells out to `bun` itself.
      buildPhase = ''
        runHook preBuild
        export HOME="$TMPDIR"
        bun run scripts/build.ts --target=bun-linux-x64 --outfile=slackcli
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm755 slackcli $out/bin/slackcli
        autoPatchelf $out/bin/slackcli
        runHook postInstall
      '';

      # Exact match, not just an exit code: a binary mangled by strip or patchelf
      # still exits 0, it just reports bun's version instead of slackcli's.
      postInstall = ''
        $out/bin/slackcli --version | grep -Fx "$version"
      '';

      # Otherwise the binary phones home to api.github.com on a 24h cache to
      # check for updates. A store path has no version metadata for it to compare
      # against, so opt out at build time rather than at each call site.
      SLACKCLI_NO_UPDATE_NOTIFIER = "1";

      meta = {
        description = "Slack CLI for reading and posting from the terminal";
        homepage = "https://github.com/shaharia-lab/slackcli";
        license = lib.licenses.mit;
        mainProgram = "slackcli";
        platforms = [ "x86_64-linux" ];
      };
    };
}
