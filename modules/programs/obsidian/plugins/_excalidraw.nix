{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-excalidraw-plugin";
  version = "2.21.2";

  src = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.21.2/main.js";
    hash = "sha256-1PE9DevBt+Z2yMsptwaXyr2kKUxjuLLAN/dDJzManio=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.21.2/manifest.json";
    hash = "sha256-sLdC7x7LgItTq2Ctbmnb79jJ27z979XMPvapgHT5AfI=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.21.2/styles.css";
    hash = "sha256-uQwnmpP5lx3zhVMj38Y7faghIY/+3oK+O2v/hRmDxM8=";
  };

  unpackPhase = "true";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp $src $out/main.js
    cp $manifest $out/manifest.json
    cp $css $out/styles.css
    runHook postInstall
  '';
}
