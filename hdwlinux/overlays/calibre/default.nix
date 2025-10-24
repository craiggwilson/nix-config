{
  lib,
  ...
}:
final: prev: {
  calibre = prev.calibre.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ lib.makeWrapper ];
    postInstall = old.postInstall or "" + ''
      wrapProgram "$out/bin/calibre" --set CALIBRE_USE_SYSTEM_THEME 1
    '';
  });
}
