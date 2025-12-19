# Tests for substrate.lib functions
# Run with: nix eval -f substrate/tests/core/lib-test.nix
{
  pkgs ? import <nixpkgs> { },
}:
let
  lib = pkgs.lib;

  # Helper to run a test and return result
  runTest =
    name: test:
    let
      result = builtins.tryEval (builtins.deepSeq test.check test.check);
    in
    if result.success then
      if result.value == true then
        { inherit name; success = true; message = "PASS"; }
      else
        { inherit name; success = false; message = "FAIL: check returned false"; }
    else
      { inherit name; success = false; message = "FAIL: evaluation error"; };

  # Evaluate a substrate configuration
  evalSubstrate =
    modules:
    lib.evalModules {
      modules = [
        ../../core/settings.nix
        ../../core/lib.nix
        ../../core/modules.nix
        ../../core/finders.nix
        ../../core/overlays.nix
        ../../core/packages.nix
      ] ++ modules;
    };

  tests = {
    # Test 1: unique deduplicates list preserving order
    uniqueDeduplicates = {
      check =
        let
          eval = evalSubstrate [ ];
          unique = eval.config.substrate.lib.unique;
        in
        unique [ 1 2 3 2 1 4 ] == [ 1 2 3 4 ];
    };

    # Test 2: unique preserves order
    uniquePreservesOrder = {
      check =
        let
          eval = evalSubstrate [ ];
          unique = eval.config.substrate.lib.unique;
        in
        unique [ "c" "a" "b" "a" "c" ] == [ "c" "a" "b" ];
    };

    # Test 3: unique handles empty list
    uniqueEmptyList = {
      check =
        let
          eval = evalSubstrate [ ];
          unique = eval.config.substrate.lib.unique;
        in
        unique [ ] == [ ];
    };

    # Test 4: extractClassModules extracts nixos modules
    extractClassModulesNixos = {
      check =
        let
          eval = evalSubstrate [ ];
          extractClassModules = eval.config.substrate.lib.extractClassModules;
          mods = [
            { nixos = { enable = true; }; homeManager = null; }
            { nixos = { enable = false; }; homeManager = { config = { }; }; }
          ];
        in
        lib.length (extractClassModules "nixos" mods) == 2;
    };

    # Test 5: extractClassModules filters null values
    extractClassModulesFiltersNull = {
      check =
        let
          eval = evalSubstrate [ ];
          extractClassModules = eval.config.substrate.lib.extractClassModules;
          mods = [
            { nixos = null; homeManager = null; }
            { nixos = { enable = true; }; homeManager = null; }
          ];
        in
        lib.length (extractClassModules "nixos" mods) == 1;
    };

    # Test 6: hasClass returns true for supported class
    hasClassSupported = {
      check =
        let
          eval = evalSubstrate [ ];
          hasClass = eval.config.substrate.lib.hasClass;
        in
        hasClass "nixos" == true;
    };

    # Test 7: hasClass returns false for unsupported class
    hasClassUnsupported = {
      check =
        let
          eval = evalSubstrate [ ];
          hasClass = eval.config.substrate.lib.hasClass;
        in
        hasClass "homeManager" == false;  # Not enabled without home-manager extension
    };

    # Test 8: mkAllOverlays includes packages overlay
    mkAllOverlaysIncludesPackages = {
      check =
        let
          eval = evalSubstrate [ ];
          mkAllOverlays = eval.config.substrate.lib.mkAllOverlays;
        in
        lib.length mkAllOverlays >= 1;
    };

    # Test 9: extraArgsGenerator returns empty attrs with no generators
    extraArgsGeneratorEmpty = {
      check =
        let
          eval = evalSubstrate [ ];
          extraArgsGenerator = eval.config.substrate.lib.extraArgsGenerator;
          args = extraArgsGenerator { hostcfg = null; usercfg = null; };
        in
        args == { };
    };

    # Test 10: extraArgsGenerator merges multiple generators
    extraArgsGeneratorMerges = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.extraArgsGenerators = [
                (_: { foo = "bar"; })
                (_: { baz = 42; })
              ];
            }
          ];
          extraArgsGenerator = eval.config.substrate.lib.extraArgsGenerator;
          args = extraArgsGenerator { hostcfg = null; usercfg = null; };
        in
        args.foo == "bar" && args.baz == 42;
    };
  };

  results = lib.mapAttrs runTest tests;
  allPassed = lib.all (r: r.success) (lib.attrValues results);
in
{
  inherit results allPassed;
  summary =
    let
      passed = lib.filter (r: r.success) (lib.attrValues results);
      failed = lib.filter (r: !r.success) (lib.attrValues results);
    in
    ''
      Lib Tests
      =========
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';
}

