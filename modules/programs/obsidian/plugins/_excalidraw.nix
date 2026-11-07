{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-excalidraw-plugin";
  version = "2.29.1";

  src = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.29.1/main.js";
    hash = "sha256-dbBzIp9DqBdFU3gy3fVPe6YsSxZU0uaQEeHJbobNsUk=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.29.1/manifest.json";
    hash = "sha256-Zf8lop2SDhCpByLS9YhqKrG4MjPK5kJMqnUOz6rK1C8=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.29.1/styles.css";
    hash = "sha256-x0PWSvHVF86cS/BWLs1cFRwhxNVDHdmVs/B/nMxxxnw=";
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
