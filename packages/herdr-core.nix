{
  substrate.packages.herdr-core =
    {
      lib,
      pkgs,
      ...
    }:
    pkgs.rustPlatform.buildRustPackage (
      finalAttrs:
      let
        # ghostty upstream vendors a zon2nix translation of its build.zig.zon
        # deps; it fetches every zig package with pinned hashes, matching the
        # layout zig's --system mode reads.
        zigDeps = pkgs.callPackage "${finalAttrs.src}/vendor/ghostty/build.zig.zon.nix" {
          name = "herdr-core-zig-cache-${finalAttrs.version}";
        };
      in
      {
        pname = "herdr-core";
        version = "0.1.21";

        # ghostty-vt compiles libghostty-vt from the vendored Ghostty submodule
        # with Zig 0.16 (crates/ghostty-vt/build.rs), so submodules must ship
        # and zig_0_16 must be on PATH.
        src = pkgs.fetchFromGitHub {
          owner = "herdrdev";
          repo = "herdr-core";
          tag = "v${finalAttrs.version}";
          fetchSubmodules = true;
          hash = "sha256-sKO8RNlz8lEc0ZUED/VKqIxPmzGxEfMMJjj9V0H0CM4=";
        };

        cargoHash = "sha256-KYWc0WORF6BNDhRcihn+tn0UqD1dF2pmR4irdsUcz7E=";

        # build.rs locates zig through the ZIG env var. Passing the absolute
        # path keeps zig out of nativeBuildInputs, because nixpkgs' zig setup
        # hook would replace the cargo buildPhase with `zig build`.
        ZIG = "${pkgs.zig_0_16}/bin/zig";

        # build.rs runs `zig build` bare, which fetches build.zig.zon packages
        # from the network. Point it at the zon2nix package set through zig's
        # offline --system mode (the same recipe ghostty's own nix build uses).
        ZIG_SYSTEM_PKGS = "${zigDeps}";

        postPatch = ''
          substituteInPlace crates/ghostty-vt/build.rs \
            --replace-fail \
              'build.current_dir(&src).args(["build", "-Demit-lib-vt", "-Doptimize=ReleaseFast", "-Dcpu=baseline"]);' \
              'build.current_dir(&src).args(["build", "-Demit-lib-vt", "-Doptimize=ReleaseFast", "-Dcpu=baseline"]).arg("--system").arg(std::env::var("ZIG_SYSTEM_PKGS").expect("ZIG_SYSTEM_PKGS must point at the prefetched zig packages"));'
        '';

        # The sandbox HOME is unwritable; give zig a global cache inside the
        # build tree (what nixpkgs' own zig hook does).
        preBuild = ''
          export ZIG_GLOBAL_CACHE_DIR="$NIX_BUILD_TOP/.zig-global-cache"
          mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
        '';

        postInstall = ''
          # hc is the conventional name of the same binary.
          ln -s herdr-core $out/bin/hc
        '';

        # The suite spawns cores, terminals, and timing watchdogs; not
        # sandbox-friendly.
        doCheck = false;

        meta = {
          description = "Terminals for coding agents that stay alive after you leave (hc)";
          homepage = "https://github.com/herdrdev/herdr-core";
          license = lib.licenses.asl20;
          mainProgram = "herdr-core";
          platforms = with lib.platforms; linux ++ darwin;
        };
      }
    );
}
