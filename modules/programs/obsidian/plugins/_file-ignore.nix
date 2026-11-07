{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "obsidian-file-ignore";
  version = "1.1.4";

  src = pkgs.fetchurl {
    url = "https://github.com/Feng6611/Obsidian-File-Ignore/releases/download/1.1.4/main.js";
    hash = "sha256-muw1gqwNc1s89Z+8w1o1Zl0uxR6FZaDT5UFWk/VU9JU=";
  };
  manifest = pkgs.fetchurl {
    url = "https://github.com/Feng6611/Obsidian-File-Ignore/releases/download/1.1.4/manifest.json";
    hash = "sha256-6xdHD6FNvubPG2ttdmJeOLE9qX5xkB5f6AEpIlDHtwA=";
  };
  css = pkgs.fetchurl {
    url = "https://github.com/Feng6611/Obsidian-File-Ignore/releases/download/1.1.4/styles.css";
    hash = "sha256-zPIGGXJuqw9qAU92RSxDqHVB7F2a4KwxCWX3iD4WzIY=";
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
