{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-folder-notes";
  version = "1.8.26";

  src = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.26/main.js";
    hash = "sha256-g9e5GBmrrDliY0nBsgrvJQOny0M5M01SEVZQrsARohY=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.26/manifest.json";
    hash = "sha256-1ocEy3h/toej1iYad+k9OclAnvHatON7/Gem+WtJNTY=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.26/styles.css";
    hash = "sha256-xzZzKIDHc3ow9xPVSW82YSpPZMzpa6sDFTl84UuXX2s=";
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
