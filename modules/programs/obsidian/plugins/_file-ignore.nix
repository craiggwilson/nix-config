{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-file-ignore";
  version = "1.1.1";

  src = pkgs.fetchurl {
    url = "https://github.com/Feng6611/Obsidian-File-Ignore/releases/download/1.1.1/main.js";
    hash = "sha256-5tMWHxAdnlJhFkHWU+oGpZ1t+HZI49H0SRX4ZvbJ0pU=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/Feng6611/Obsidian-File-Ignore/releases/download/1.1.1/manifest.json";
    hash = "sha256-xZfjtD0Q/qXT8YlFcgreCQ5KmaNCxE8Tgu8ueGFfmk0=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/Feng6611/Obsidian-File-Ignore/releases/download/1.1.1/styles.css";
    hash = "sha256-L+WAQUtVhN/cXaql5RODB89eAma59+TRLzNXUJ48xUE=";
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
