let
  nixpkgs = import <nixpkgs> { };
  lib = nixpkgs.lib.extend (_: prev: prev // import ./lib/default.nix { lib = prev; });
in
{
  create =
    module:
    let
      result = lib.evalModules {
        modules =
          lib.bootstrap.readFilesRecursive {
            dir = ./modules;
            filter = _: true;
          }
          ++ lib.toList module;
      };

      config = result.config;

      withWarnings =
        value:
        let
          logged = builtins.map (item: builtins.trace "Warning: ${item}" null) config.warnings;
        in
        builtins.deepSeq logged value;

      assertions = builtins.filter (item: !item.assertion) config.assertions;

      failure =
        let
          formatted = builtins.map (item: "Assertion: ${item.message}") assertions;
        in
        (builtins.throw "\n\n${builtins.concatStringsSep "\n" formatted}");

      resolved =
        if builtins.length assertions > 0 then
          builtins.addErrorContext "Some assertions failed!" failure
        else
          result.config;
    in
    withWarnings resolved;
}
