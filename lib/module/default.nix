{ lib, ... }:
with lib;
rec {
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  mkBoolOpt = mkOpt types.bool;
  mkEnableOpt = req: tags: mkBoolOpt (elemsAll req tags) "Enabled.";
  mkStrOpt = mkOpt types.str;
  mkNullStrOpt = mkOpt (types.nullOr types.str);

  elemsAll = x: xs: builtins.all (e: builtins.elem e xs) x;

  # not exactly very optimized, but it gets the job done for a small number of elements.
  uniqueBy =
    f: builtins.foldl' (acc: e: if builtins.elem (f e) (map f acc) then acc else acc ++ [ e ]) [ ];
}
