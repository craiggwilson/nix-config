{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-terminal";
  version = "3.23.0";

  src = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.23.0/main.js";
    hash = "sha256-AxtoMtcGUX/UB0S2KtSmqyEdjLe8kng5VY0fjP/8YAo=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.23.0/manifest.json";
    hash = "sha256-XhBrTT5aYs/DWYV8lP2P3S+IrAWPIORrNUFmrk5ZMGA=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.23.0/styles.css";
    hash = "sha256-cVp9j7TXFXupaMkJsRHQP9bCSFOszx3Pqe1D/dg6yg4=";
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
