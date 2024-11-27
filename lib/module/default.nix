{ lib, ... }:
let
  elemsAny = x: xs: builtins.any (e: elemPrefix e xs) x;
  elemPrefix = x: xs: builtins.any (e: lib.strings.hasPrefix x e) xs;
in
rec {
  getAppExe =
    app: argGroup:
    let
      path = if app.program != null then lib.getExe' app.package app.program else lib.getExe app.package;
      args =
        if argGroup == "default" && !builtins.hasAttr "default" app.args then
          ""
        else
          " " + (lib.strings.concatStringsSep " " app.args.${argGroup});
    in
    "${path}${args}";

  getAppExe' = app: getAppExe app "default";

  getAppProgram = app: if app.program != null then app.program else app.package.meta.mainProgram;

  mkEnableOption =
    name: default:
    lib.mkOption {
      description = "Whether to enable ${name}.";
      type = lib.types.bool;
      default = default;
    };

  matchTag = match: tags: elemPrefix match tags;
  matchTags =
    match: tags:
    builtins.all (
      e:
      if builtins.isString e then
        matchTag e tags
      else if builtins.isList e then
        elemsAny e tags
      else
        throw "match must be a string or a list of strings"
    ) match;

  toTitle =
    str: "${lib.toUpper (lib.substring 0 1 str)}${lib.substring 1 (lib.stringLength str) str}";
}
