{
  substrate.packages.herdr-app =
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
          name = "herdr-app-zig-cache-${finalAttrs.version}";
        };
      in
      {
        pname = "herdr-app";
        version = "0.1.15";

        # ghostty-sys compiles libghostty-vt from the vendored Ghostty
        # submodule with Zig 0.16 (crates/ghostty-sys/build.rs), so submodules
        # must ship.
        src = pkgs.fetchFromGitHub {
          owner = "herdrdev";
          repo = "herdr-app";
          tag = "v${finalAttrs.version}";
          fetchSubmodules = true;
          hash = "sha256-CNktD+tQrMMN4vpzFPZkZWnwDalaTkUV0A2UiLVeO3E=";
        };

        cargoHash = "sha256-usCdairGam65XVKtb1jJpRC0tNXnoafAnMFQjPgvgqQ=";

        # gpui (Zed's UI framework) system-library set, following the nixpkgs
        # zed recipe.
        buildInputs = [
          pkgs.alsa-lib
          pkgs.fontconfig
          pkgs.glib
          pkgs.libGL
          pkgs.libx11
          pkgs.libxext
          pkgs.libxcb
          pkgs.libxkbcommon
          pkgs.openssl
          pkgs.wayland
          pkgs.zlib
          pkgs.zstd
        ];

        nativeBuildInputs = [
          pkgs.llvmPackages.libclang
          pkgs.pkg-config
        ];

        # ghostty-sys runs bindgen against ghostty's C headers.
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

        # ghostty-sys locates zig through the ZIG env var. Passing the
        # absolute path keeps zig out of nativeBuildInputs, because nixpkgs'
        # zig setup hook would replace the cargo buildPhase with `zig build`.
        ZIG = "${pkgs.zig_0_16}/bin/zig";

        # ghostty-sys runs `zig build` bare, which fetches build.zig.zon
        # packages from the network. Point it at the zon2nix package set
        # through zig's offline --system mode.
        ZIG_SYSTEM_PKGS = "${zigDeps}";

        # The sandbox HOME is unwritable; give zig a global cache inside the
        # build tree.
        preBuild = ''
          export ZIG_GLOBAL_CACHE_DIR="$NIX_BUILD_TOP/.zig-global-cache"
          mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
        '';

        postPatch = ''
          substituteInPlace crates/ghostty-sys/build.rs \
            --replace-fail \
              '.args(["build", "-Demit-lib-vt", "-Demit-xcframework=false", "-Doptimize=ReleaseFast"])' \
              '.args(["build", "-Demit-lib-vt", "-Demit-xcframework=false", "-Doptimize=ReleaseFast"]).arg("--system").arg(std::env::var("ZIG_SYSTEM_PKGS").expect("ZIG_SYSTEM_PKGS must point at the prefetched zig packages"))'
        '';

        postInstall = ''
          install -Dm 0644 assets/icons/herdr-ui-icon-clean.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg
          mkdir -p $out/share/applications
          cat > $out/share/applications/herdr-app.desktop <<DESKTOP
          [Desktop Entry]
          Type=Application
          Name=Herdr
          Comment=Desktop app for running coding agents
          Exec=herdr-app
          Icon=herdr-app
          Terminal=false
          StartupWMClass=herdr-app
          Categories=Development;
          DESKTOP
        '';

        # GUI suite; not sandbox-friendly.
        doCheck = false;

        # gpui dlopens GL/Vulkan/wayland at runtime (zed recipe).
        postFixup = ''
          patchelf $out/bin/herdr-app --add-rpath ${
            lib.makeLibraryPath [
              pkgs.libGL
              pkgs.vulkan-loader
              pkgs.wayland
            ]
          }
        '';

        meta = {
          description = "Herdr desktop app for running coding agents";
          homepage = "https://herdr.dev";
          license = lib.licenses.asl20;
          mainProgram = "herdr-app";
          platforms = lib.platforms.linux;
        };
      }
    );
}
