{
  channels,
  ...
}:
final: prev: {
  ags = prev.ags.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ channels.nixpkgs.libdbusmenu-gtk3 ];
  });
}
