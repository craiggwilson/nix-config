{ lib, ... }:
let
  onlyDirsFilter = _: type: type == "directory";
  onlyFilesFilter = _: type: type == "regular";
  defaultNixNameFilter = name: name == "default.nix";

  elemsAny = x: xs: builtins.any (e: elemPrefix e xs) x;
  elemPrefix = x: xs: builtins.any (e: lib.strings.hasPrefix x e) xs;

  findFilesRecursive =
    {
      dir,
      filter ? defaultNixNameFilter,
    }:
    let
      entries = builtins.readDir dir;
      subdirs = lib.filterAttrs onlyDirsFilter entries;
      files = lib.mapAttrsToList (name: _: dir + "/${name}") (
        lib.filterAttrs (name: type: (onlyFilesFilter name type) && (filter name)) entries
      );
      files' = lib.mapAttrsToList (
        name: _:
        findFilesRecursive {
          inherit filter;
          dir = dir + "/${name}";
        }
      ) subdirs;
    in
    lib.flatten (files ++ files');

  findSubdirFilesRecursive =
    {
      dir,
      filter ? defaultNixNameFilter,
    }:
    let
      entries = builtins.readDir dir;
      subdirs = lib.filterAttrs onlyDirsFilter entries;
      files = lib.mapAttrsToList (
        name: _:
        findFilesRecursive {
          inherit filter;
          dir = dir + "/${name}";
        }
      ) subdirs;
    in
    lib.flatten files;

  flatMap =
    e: m: list:
    lib.lists.flatten (builtins.map (x: builtins.map (y: (m x y)) (e x)) list);

  getAppExe =
    app: argGroup:
    let
      path = if app.program != null then lib.getExe' app.package app.program else lib.getExe app.package;
      args =
        if argGroup == "default" && !builtins.hasAttr "default" app.argGroups then
          ""
        else
          " " + (lib.strings.concatStringsSep " " app.argGroups.${argGroup});
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

  monitorDescription =
    monitor:
    "${monitor.vendor} ${monitor.model}"
    + (if monitor.serial != null then " ${monitor.serial}" else "");

  toTitle =
    str: "${lib.toUpper (lib.substring 0 1 str)}${lib.substring 1 (lib.stringLength str) str}";
in
{
  hdwlinux = {
    inherit
      findFilesRecursive
      findSubdirFilesRecursive
      flatMap
      getAppExe
      getAppExe'
      getAppProgram
      mkEnableOption
      matchTag
      matchTags
      monitorDescription
      toTitle
      ;

    file = import ./file;
    theme = import ./theme;
    types = import ./types { inherit lib; };
  };
}
