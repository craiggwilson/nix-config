{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-terminal";
  version = "3.27.1";

  src = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.27.1/main.js";
    hash = "sha256-/5m87A0EJSJ0KUECii52a6L4JHjbv8RhxfWMJY7wIE8=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.27.1/manifest.json";
    hash = "sha256-1bhdzHSfYoAkrIpm3D0Q5p0RU/wTU5Nf8ch72xpQMvg=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.27.1/styles.css";
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
