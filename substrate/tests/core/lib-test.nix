# Tests for substrate.lib functions
# Run with: nix eval -f substrate/tests/core/lib-test.nix
{
  pkgs ? import <nixpkgs> { },
}:
let
  testLib = import ../lib.nix { inherit pkgs; };
  inherit (testLib) lib evalSubstrate runTests;

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

    # Test 11: extractClassModules includes generic modules for nixos
    extractClassModulesIncludesGenericForNixos = {
      check =
        let
          eval = evalSubstrate [ ];
          extractClassModules = eval.config.substrate.lib.extractClassModules;
          mods = [
            { generic = { shared = true; }; nixos = null; }
            { generic = null; nixos = { enable = true; }; }
          ];
        in
        lib.length (extractClassModules "nixos" mods) == 2;
    };

    # Test 12: extractClassModules includes generic modules for homeManager
    extractClassModulesIncludesGenericForHomeManager = {
      check =
        let
          eval = evalSubstrate [ ];
          extractClassModules = eval.config.substrate.lib.extractClassModules;
          mods = [
            { generic = { shared = true; }; homeManager = null; }
            { generic = null; homeManager = { config = { }; }; }
          ];
        in
        lib.length (extractClassModules "homeManager" mods) == 2;
    };

    # Test 13: extractClassModules with both generic and specific modules
    extractClassModulesBothGenericAndSpecific = {
      check =
        let
          eval = evalSubstrate [ ];
          extractClassModules = eval.config.substrate.lib.extractClassModules;
          mods = [
            { generic = { shared = true; }; nixos = { specific = true; }; }
          ];
          result = extractClassModules "nixos" mods;
        in
        lib.length result == 2;
    };

    # Test 14: extractClassModules for generic class does not double-include generic
    extractClassModulesGenericClassNoDoubleInclude = {
      check =
        let
          eval = evalSubstrate [ ];
          extractClassModules = eval.config.substrate.lib.extractClassModules;
          mods = [
            { generic = { shared = true; }; nixos = null; }
          ];
        in
        lib.length (extractClassModules "generic" mods) == 1;
    };
  };
in
runTests "Lib Tests" tests

