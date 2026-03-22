{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-folder-notes";
  version = "1.8.18";

  src = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.18/main.js";
    hash = "sha256-cKfmP3et7CjFGMpmdQR6gXJDeyVIzyQjEbTkrUBklmo=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.18/manifest.json";
    hash = "sha256-B5pyhMhC6BYl9TP1Dt4TiLdRwYp83D3tlX4f3zw53os=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.18/styles.css";
    hash = "sha256-fyZ2VrJ8++uc3qApb9QCmA8MFvCSCuPkr/7npE9A2TA=";
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
