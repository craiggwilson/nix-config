{
  fromAttrs =
    theme:
    let
      withHashtag = builtins.mapAttrs (_: value: "#" + value) theme;

      themeFull = theme // {
        inherit withHashtag;
      };
    in
    themeFull
    // {
      adwaitaGtkCss = (import ./templates/adwaitaGtkCss.nix) themeFull;
    };
}
