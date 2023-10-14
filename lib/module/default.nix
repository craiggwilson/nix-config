{ lib, ... }:
with lib; rec {
  mkOpt = type: default: description: mkOption { inherit type default description; };

  mkBoolOpt = mkOpt types.bool;
  mkStrOpt = mkOpt types.str;
  mkNullStrOpt = mkOpt (types.nullOr types.str);

  # not exactly very optimized, but it gets the job done for a small number of elements.
  uniqueBy = f: builtins.foldl' (acc: e: if builtins.elem (f e) (map f acc) then acc else acc ++ [ e ]) [];
}
