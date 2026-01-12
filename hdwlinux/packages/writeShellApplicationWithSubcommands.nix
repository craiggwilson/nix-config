{ lib, pkgs, ... }:
let
  indentLines =
    indent: str:
    let
      lines = lib.strings.splitString "\n" str;
      indentLine = line: if line == "" then "" else "${indent}${line}";
    in
    lib.strings.concatMapStringsSep "\n" indentLine lines;

  writeRecipe =
    name: script: isDefault:
    let
      trimmedScript = lib.strings.trim script;
      lines = lib.strings.splitString "\n" trimmedScript;
      isMultiLine = builtins.length lines > 1;
      indentedScript = indentLines "    " trimmedScript;
      attr = if isDefault then "[private, no-cd]" else "[no-cd]";
    in
    if isMultiLine then
      lib.strings.concatStringsSep "\n" [
        attr
        "${name} *args:"
        "    #!/usr/bin/env bash"
        "    set -euo pipefail"
        indentedScript
        ""
      ]
    else
      lib.strings.concatStringsSep "\n" [
        attr
        "@${name} *args:"
        "    ${trimmedScript}"
        ""
      ];

  processSubcommands =
    appName: prefix: subcommands:
    let
      processOne =
        name: value:
        if builtins.isAttrs value then
          let
            moduleName = if prefix == "" then name else "${prefix}-${name}";
            child = processSubcommands appName moduleName value;
            moduleContent = lib.strings.concatStringsSep "\n" [
              "set quiet"
              "set positional-arguments"
              ""
              (lib.strings.concatStringsSep "\n" child.mods)
              child.recipes
            ];
            moduleFile = pkgs.writeText "${appName}-${moduleName}.just" moduleContent;
          in
          {
            files = child.files ++ [ moduleFile ];
            mods = [ "mod ${name} '${moduleFile}'" ];
            recipes = "";
          }
        else
          let
            script = if builtins.isPath value then builtins.readFile value else value;
          in
          {
            files = [ ];
            mods = [ ];
            recipes = writeRecipe name script false;
          };

      results = lib.mapAttrsToList processOne (lib.filterAttrs (n: _: n != "*") subcommands);

      defaultRecipe =
        if builtins.hasAttr "*" subcommands then writeRecipe "default" subcommands."*" true else "";
    in
    {
      files = lib.flatten (map (r: r.files) results);
      mods = lib.flatten (map (r: r.mods) results);
      recipes = lib.strings.concatStringsSep "\n" ([ defaultRecipe ] ++ (map (r: r.recipes) results));
    };
in
{
  name,
  runtimeInputs ? [ ],
  subcommands,
}:
let
  processed = processSubcommands name "" subcommands;
  mainContent = lib.strings.concatStringsSep "\n" [
    "set quiet"
    "set positional-arguments"
    ""
    (lib.strings.concatStringsSep "\n" processed.mods)
    processed.recipes
  ];
  justfile = pkgs.writeText "${name}.just" mainContent;
in
pkgs.writeShellApplication {
  inherit name;
  runtimeInputs = runtimeInputs ++ [ pkgs.just ];
  text = ''
    flags=()
    args=()
    for arg in "$@"; do
      if [[ "$arg" == -* ]]; then
        flags+=("$arg")
      else
        args+=("$arg")
      fi
    done
    exec just --list-submodules --justfile "${justfile}" --working-directory "$(pwd)" "''${flags[@]}" "''${args[@]}"
  '';
}
