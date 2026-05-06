{ lib, pkgs, ... }:
let
  version = "1.7.0";
in
pkgs.stdenv.mkDerivation {
  pname = "openwhispr";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/OpenWhispr/openwhispr/releases/download/v${version}/OpenWhispr-${version}-linux-x64.tar.gz";
    hash = "sha256-+p/E767QCKOMavqA3cRz5m8/3BvTyF+moQUj7p96bL8=";
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.wrapGAppsHook3
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.alsa-lib
    pkgs.at-spi2-atk
    pkgs.at-spi2-core
    pkgs.atk
    pkgs.cairo
    pkgs.cups
    pkgs.dbus
    pkgs.expat
    pkgs.glib
    pkgs.gtk3
    pkgs.libdrm
    pkgs.libxkbcommon
    pkgs.mesa
    pkgs.nspr
    pkgs.nss
    pkgs.pango
    pkgs.stdenv.cc.cc
    pkgs.systemd
    pkgs.udev
    pkgs.libx11
    pkgs.libxcomposite
    pkgs.libxcursor
    pkgs.libxdamage
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxi
    pkgs.libxrandr
    pkgs.libxrender
    pkgs.libxtst
    pkgs.libxcb
    pkgs.libxshmfence
  ];

  dontBuild = true;
  dontConfigure = true;
  dontPatchELF = false;

  # CUDA/TensorRT providers are optional GPU acceleration libs not available
  # without NVIDIA drivers; ignore them so the CPU-only path still works.
  autoPatchelfIgnoreMissingDeps = [
    "libcublasLt.so.12"
    "libcublas.so.12"
    "libcurand.so.10"
    "libcufft.so.11"
    "libcudart.so.12"
    "libcudnn.so.9"
    "libnvinfer.so.10"
    "libnvonnxparser.so.10"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/openwhispr $out/bin

    # Copy all app files
    cp -r . $out/share/openwhispr/

    # Make main binaries executable
    chmod +x $out/share/openwhispr/open-whispr
    chmod +x $out/share/openwhispr/open-whispr-app

    # Wrap the launcher so it uses the correct path and has required libs
    makeWrapper $out/share/openwhispr/open-whispr $out/bin/openwhispr \
      --set ELECTRON_IS_DEV 0 \
      --set ELECTRON_ENABLE_LOGGING 0

    runHook postInstall
  '';

  meta = {
    description = "Privacy-first voice-to-text dictation with local and cloud models";
    homepage = "https://github.com/OpenWhispr/openwhispr";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "openwhispr";
  };
}
