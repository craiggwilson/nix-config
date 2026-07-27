{ lib, pkgs, ... }:
let
  pname = "orca-ide";
  version = "1.4.158";
  src = pkgs.fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-8F8ZOduQAPug806rWnA3K5zeTCFQNdkLPKYDXO/Y/C0=";
  };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    # Runtime deps from deb packaging
    python3
    xdotool
    xclip
    # GTK/GLib for Electron
    glib
    gtk3
    nss
    cups
    libdrm
    mesa
    pango
    cairo
    alsa-lib
    atk
    libuuid
    expat
    freetype
    fontconfig
    zlib
  ];

  extraInstallCommands = ''
    mv $out/bin/${pname} $out/bin/${pname}-wrapped

    cat > $out/bin/${pname} << 'WRAPPER'
    #!/bin/sh
    export NIXOS_OZONE_WL=1
    exec "$(dirname "$0")/${pname}-wrapped" "$@"
    WRAPPER
    chmod +x $out/bin/${pname}

    mkdir -p $out/share/applications
    cat > $out/share/applications/${pname}.desktop << 'DESKTOP'
    [Desktop Entry]
    Name=Orca
    Comment=AI Orchestrator for parallel agentic development
    Exec=orca-ide %U
    Icon=orca-ide
    Type=Application
    Categories=Development;IDE;
    StartupWMClass=orca
    DESKTOP
  '';

  meta = with lib; {
    description = "AI Orchestrator for parallel agentic development - run Codex, Claude Code, OpenCode side-by-side";
    homepage = "https://github.com/stablyai/orca";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = pname;
  };
}
