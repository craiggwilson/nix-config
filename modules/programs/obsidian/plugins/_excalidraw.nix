{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-excalidraw-plugin";
  version = "2.26.4";

  src = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.26.4/main.js";
    hash = "sha256-sm8/yM+jnP7+jBHILkP4Cv3GQtjKTU7OO92Bf3LUz1o=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.26.4/manifest.json";
    hash = "sha256-9rgX2uovohBmcaYtcjbNyNgG9SRl8f86tTQyMcAgtwM=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.26.4/styles.css";
    hash = "sha256-YVtWDFGTsspO8/8YRNKAeRO8UcQDM8ef3QioQLDEJzU=";
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
