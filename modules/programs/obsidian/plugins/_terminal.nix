{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-terminal";
  version = "3.29.0";

  src = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.29.0/main.js";
    hash = "sha256-prj33l0S2ieqTMJG14/4K9x2vHOejyyUgm5vPeKTtp8=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.29.0/manifest.json";
    hash = "sha256-Pf0/ysY/TbdJHFUGpxbFIhNZYxoNfm0QuOHUYQUr0mk=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/polyipseity/obsidian-terminal/releases/download/3.29.0/styles.css";
    hash = "sha256-BOnyZ+LDhMGavyCOch678g5ornFZO4MIoJtqWCddN9U=";
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
