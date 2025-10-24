{ lib }:
let
  onlyDirsFilter = _: type: type == "directory";
  onlyFilesFilter = _: type: type == "regular";
  defaultNixNameFilter = name: name == "default.nix";

  loadFilesRecursive =
    {
      dir,
      filter ? defaultNixNameFilter,
      args,
    }:
    let
      files = readFilesRecursive { inherit dir filter; };
    in
    builtins.map (f: import f args) files;

  mergeAttrs = builtins.foldl' lib.mergeAttrs { };

  mergeAttrsRecursive = builtins.foldl' lib.recursiveUpdate { };

  extendPkgsLib =
    { pkgs, libs }:
    let
      userlib = lib.fix (
        userlib:
        let
          attrs = {
            lib = pkgs.lib // userlib;
          };
        in
        mergeAttrsRecursive (
          builtins.map (
            path:
            let
              imported = import path;
            in
            if lib.isFunction imported then lib.callPackageWith attrs path { } else imported
          ) libs
        )
      );
    in
    pkgs.lib.extend (
      _: prev:
      mergeAttrsRecursive [
        prev
        userlib
      ]
    );

  mkFlakeInput =
    {
      inputs,
    }:
    {
      settings.inputs = inputs;
    };

  readFilesRecursive =
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
        readFilesRecursive {
          inherit filter;
          dir = dir + "/${name}";
        }
      ) subdirs;
    in
    lib.flatten (files ++ files');

in
{
  bootstrap = {
    inherit
      extendPkgsLib
      loadFilesRecursive
      mergeAttrs
      mergeAttrsRecursive
      mkFlakeInput
      readFilesRecursive
      ;
  };
}
