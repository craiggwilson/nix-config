{ lib, pkgs, ... }:
let
  version = "0.3.0";
  pnpm = pkgs.pnpm_10;

  src = pkgs.fetchFromGitHub {
    owner = "Zackriya-Solutions";
    repo = "meetily";
    tag = "v${version}";
    hash = "sha256-JmonSa1mrFg6rRNSyGxbjJ/Zw+bg4p82n3sPfq8rH7A=";
  };

  # Patched source with lockfiles injected (neither is committed upstream)
  patchedSrc = pkgs.stdenvNoCC.mkDerivation {
    name = "meetily-src-${version}";
    inherit src;

    phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];

    # Skip ffmpeg download (Nix sandbox blocks network); remove Google Fonts dependency
    patches = [
      ./skip-ffmpeg-download.patch
      ./fix-google-fonts.patch
    ];

    buildPhase = ''
      # Inject pnpm lockfile (not in upstream repo)
      cp ${./pnpm-lock.yaml} frontend/pnpm-lock.yaml
      # Inject Cargo.lock (not in upstream repo)
      # cargoSetupHook expects it at {cargoRoot}/Cargo.lock = frontend/src-tauri/Cargo.lock
      cp ${./Cargo.lock} Cargo.lock
      cp ${./Cargo.lock} frontend/src-tauri/Cargo.lock

      # Fix Tauri macro naming: the source only re-exports __cmd__ wrappers,
      # but tauri-macros >= 2.6.0 generate_handler! also needs __tauri_command_name_* macros
      # Add re-exports for the __tauri_command_name__ macros alongside the existing __cmd__ ones
      substituteInPlace frontend/src-tauri/src/summary/mod.rs \
        --replace-fail \
          'pub use commands::{
    __cmd__api_cancel_summary, __cmd__api_get_summary, __cmd__api_process_transcript,
    __cmd__api_save_meeting_summary, api_cancel_summary, api_get_summary,
    api_process_transcript, api_save_meeting_summary,
};

// Re-export template commands
pub use template_commands::{
    __cmd__api_get_template_details, __cmd__api_list_templates, __cmd__api_validate_template,
    api_get_template_details, api_list_templates, api_validate_template,
};' \
          'pub use commands::{
    __cmd__api_cancel_summary, __cmd__api_get_summary, __cmd__api_process_transcript,
    __cmd__api_save_meeting_summary, api_cancel_summary, api_get_summary,
    api_process_transcript, api_save_meeting_summary,
    __tauri_command_name_api_cancel_summary, __tauri_command_name_api_get_summary,
    __tauri_command_name_api_process_transcript, __tauri_command_name_api_save_meeting_summary,
};

// Re-export template commands
pub use template_commands::{
    __cmd__api_get_template_details, __cmd__api_list_templates, __cmd__api_validate_template,
    api_get_template_details, api_list_templates, api_validate_template,
    __tauri_command_name_api_get_template_details, __tauri_command_name_api_list_templates,
    __tauri_command_name_api_validate_template,
};'

      substituteInPlace frontend/src-tauri/src/summary/summary_engine/mod.rs \
        --replace-fail \
          'pub use commands::{
    __cmd__builtin_ai_cancel_download, __cmd__builtin_ai_delete_model,
    __cmd__builtin_ai_download_model, __cmd__builtin_ai_get_available_summary_model,
    __cmd__builtin_ai_get_model_info, __cmd__builtin_ai_get_recommended_model, __cmd__builtin_ai_is_model_ready,
    __cmd__builtin_ai_list_models, builtin_ai_cancel_download, builtin_ai_delete_model, builtin_ai_download_model,
    builtin_ai_get_available_summary_model, builtin_ai_get_model_info, builtin_ai_get_recommended_model, builtin_ai_is_model_ready,
    builtin_ai_list_models, init_model_manager, ModelManagerState,
};' \
          'pub use commands::{
    __cmd__builtin_ai_cancel_download, __cmd__builtin_ai_delete_model,
    __cmd__builtin_ai_download_model, __cmd__builtin_ai_get_available_summary_model,
    __cmd__builtin_ai_get_model_info, __cmd__builtin_ai_get_recommended_model, __cmd__builtin_ai_is_model_ready,
    __cmd__builtin_ai_list_models, builtin_ai_cancel_download, builtin_ai_delete_model, builtin_ai_download_model,
    builtin_ai_get_available_summary_model, builtin_ai_get_model_info, builtin_ai_get_recommended_model, builtin_ai_is_model_ready,
    builtin_ai_list_models, init_model_manager, ModelManagerState,
    __tauri_command_name_builtin_ai_cancel_download, __tauri_command_name_builtin_ai_delete_model,
    __tauri_command_name_builtin_ai_download_model, __tauri_command_name_builtin_ai_get_available_summary_model,
    __tauri_command_name_builtin_ai_get_model_info, __tauri_command_name_builtin_ai_get_recommended_model,
    __tauri_command_name_builtin_ai_is_model_ready, __tauri_command_name_builtin_ai_list_models,
};'
    '';

    installPhase = ''
      cp -r . $out
    '';
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "meetily";
    inherit version;
    src = patchedSrc;
    inherit pnpm;
    sourceRoot = "meetily-src-${version}/frontend";
    fetcherVersion = 3;
    hash = "sha256-PbXqCwayWT2vBk3z4/EthmuUl5gpmtRgH3l4aIiEU7w=";
  };

in
pkgs.rustPlatform.buildRustPackage {
  pname = "meetily";
  inherit version;

  # Some tests require FFmpeg or network, disable them in Nix sandbox
  doCheck = false;

  src = patchedSrc;

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "silero-0.1.0" = "sha256-1d9xXvvvgPOZ5FZsZYvvWVlfgCsDZmIKNxFZBuxc5Fo=";
      "ffmpeg-sidecar-2.5.0" = "sha256-/fYkQTCAogaDfJbspQEpkVTux/yJlpSnTnS/xmYNUmE=";
      "cidre-0.11.3" = "sha256-6bXfAbR1E5u3+fZl5XzuRHHSZLpGR8mHJcX1fq14Dwk=";
    };
  };

  inherit pnpmDeps;

  nativeBuildInputs = [
    pkgs.cargo-tauri.hook
    pkgs.pnpmConfigHook
    pnpm
    pkgs.nodejs
    pkgs.pkg-config
    pkgs.jq
    pkgs.moreutils
    pkgs.cmake
    pkgs.wrapGAppsHook4
    # whisper-rs-sys needs bindgen which needs libclang
    pkgs.llvmPackages.libclang.lib
  ];

  buildInputs = [
    pkgs.glib-networking
    pkgs.libayatana-appindicator
    pkgs.libsoup_3
    pkgs.openssl
    pkgs.sqlite
    pkgs.webkitgtk_4_1
    pkgs.alsa-lib
    pkgs.dbus
    pkgs.onnxruntime
  ];

  # The Rust workspace root is at the repo root, the Tauri app is in frontend/src-tauri
  cargoRoot = "frontend/src-tauri";
  buildAndTestSubdir = "frontend/src-tauri";

  # Point pnpmConfigHook to the frontend/ directory where package.json lives
  pnpmRoot = "frontend";

  env = {
    # Use system ONNX Runtime instead of downloading it at build time
    ORT_LIB_LOCATION = "${pkgs.onnxruntime}/lib";
    ORT_DYLIB_PATH = "${pkgs.onnxruntime}/lib/libonnxruntime.so";
    OPENSSL_NO_VENDOR = 1;
    # Use pkg-config for sqlite
    LIBSQLITE3_SYS_USE_PKG_CONFIG = 1;
    # Tell bindgen (used by whisper-rs-sys) where to find libclang
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
  };

  postPatch = ''
    # Disable auto-updater and remove external binaries from bundle
    # (ffmpeg is provided via system PATH at runtime)
    jq '
      .bundle.createUpdaterArtifacts = false |
      .plugins.updater = {"active": false, "pubkey": "", "endpoints": []} |
      del(.bundle.externalBin)
    ' frontend/src-tauri/tauri.conf.json | sponge frontend/src-tauri/tauri.conf.json

    # Remove macOS-only cargo config that overrides the linker
    rm -f frontend/src-tauri/.cargo/config.toml

    # libappindicator-sys dlopen()s the library by bare name at runtime; patch it
    # to use the absolute Nix store path so it is found without LD_LIBRARY_PATH.
    substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
      --replace-fail \
        '"libayatana-appindicator3.so.1"' \
        '"${pkgs.libayatana-appindicator}/lib/libayatana-appindicator3.so.1"'
  '';

  preFixup = ''
    # Ensure ffmpeg is accessible at runtime (app falls back to PATH search)
    gappsWrapperArgs+=(
      --suffix PATH : ${lib.makeBinPath [ pkgs.ffmpeg ]}
    )
  '';

  meta = {
    description = "Privacy-first AI meeting assistant with local transcription and summarization";
    homepage = "https://github.com/Zackriya-Solutions/meetily";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "meetily";
  };
}
