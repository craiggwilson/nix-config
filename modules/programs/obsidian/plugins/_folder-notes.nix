{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-folder-notes";
  version = "1.8.24";

  src = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.24/main.js";
    hash = "sha256-8E9jliG9aPxYxtIEjDqR429CsFLt18K6Fn8kJ0sJBZU=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.24/manifest.json";
    hash = "sha256-9MRqXEN2OOdmiWgdg4V8G9MgSAMw38CMss69C/77VA4=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/LostPaul/obsidian-folder-notes/releases/download/1.8.24/styles.css";
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
