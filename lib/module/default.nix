{ lib, ... }:
rec {
  mkOpt =
    type: default: description:
    lib.mkOption { inherit type default description; };

  mkBoolOpt = mkOpt lib.types.bool;
  mkEnableOpt = req: tags: mkBoolOpt (elemsAll req tags) "Enabled.";
  mkEnableTagsOpt =
    name: req: tags:
    mkBoolOpt (elemsAll req tags) "Whether to enable ${name}.";
  mkStrOpt = mkOpt lib.types.str;
  mkNullStrOpt = mkOpt (lib.types.nullOr lib.types.str);

  mkEnableOption =
    name: default:
    lib.mkOption {
      description = "Whether to enable ${name}.";
      type = lib.types.bool;
      default = default;
    };

  elemsAll = x: xs: builtins.all (e: elemPrefix e xs) x;
  elemsAny = x: xs: builtins.any (e: elemPrefix e xs) x;
  elemPrefix = x: xs: builtins.any (e: lib.strings.hasPrefix x e) xs;

  toTitle =
    str: "${lib.toUpper (lib.substring 0 1 str)}${lib.substring 1 (lib.stringLength str) str}";

  # not exactly very optimized, but it gets the job done for a small number of elements.
  uniqueBy =
    f: builtins.foldl' (acc: e: if builtins.elem (f e) (map f acc) then acc else acc ++ [ e ]) [ ];
}
