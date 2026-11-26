{
  substrate.publish.packages.narratrix =
    { lib, pkgs, ... }:
    let
      version = "1.0.1";
      pnpm = pkgs.pnpm_11;
    in
    pkgs.rustPlatform.buildRustPackage (finalAttrs: {
      pname = "narratrix";
      inherit version;

      src = pkgs.fetchFromGitHub {
        owner = "vitorfdl";
        repo = "narratrix";
        rev = version;
        hash = "sha256-i0Gh/7B/FxgIzj9BShE9cBPlpAtKS9MDSkQohJbV+kc=";
      };

      cargoRoot = "src-tauri";
      buildAndTestSubdir = "src-tauri";
      cargoHash = "sha256-OLSh9ozaO0UDqWAuk+xVcm3EwC80mpHPhWAhat9IqVE=";

      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs) pname version src;
        inherit pnpm;
        fetcherVersion = 4;
        hash = "sha256-2iguP/cLLCQqy9copVFSGK03k2gyI3/jvxxGEdc8Poc=";
      };

      postPatch = ''
        substituteInPlace src-tauri/tauri.conf.json \
          --replace-fail '"createUpdaterArtifacts": true' '"createUpdaterArtifacts": false'
        substituteInPlace src/App.tsx \
          --replace-fail 'import { checkForUpdates } from "./services/updater";' "" \
          --replace-fail '    checkForUpdates();' ""
      '';

      nativeBuildInputs = [
        pkgs.cargo-tauri.hook
        pkgs.nodejs_24
        pkgs.pkg-config
        pkgs.pnpmConfigHook
        pkgs.wrapGAppsHook4
        pnpm
      ];

      buildInputs = [
        pkgs.alsa-lib
        pkgs.dbus
        pkgs.glib-networking
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gtk3
        pkgs.libayatana-appindicator
        pkgs.librsvg
        pkgs.openssl
        pkgs.webkitgtk_4_1
      ];

      meta = {
        description = "Desktop AI roleplay and tabletop campaign manager";
        homepage = "https://github.com/vitorfdl/narratrix";
        license = lib.licenses.agpl3Only;
        mainProgram = "narratrix";
        platforms = [ "x86_64-linux" ];
      };
    });
}
