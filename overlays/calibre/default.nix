{
  channels,
  ...
}:

final: prev: {

  calibre = prev.calibre.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ channels.nixpkgs.makeWrapper ];
    postInstall =
      old.postInstall or ""
      + ''
        wrapProgram "$out/bin/calibre" --set CALIBRE_USE_SYSTEM_THEME 1
      '';
  });
}
