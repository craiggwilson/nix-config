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
        unique [
          1
          2
          3
          2
          1
          4
        ] == [
          1
          2
          3
          4
        ];
    };

    # Test 2: unique preserves order
    uniquePreservesOrder = {
      check =
        let
          eval = evalSubstrate [ ];
          unique = eval.config.substrate.lib.unique;
        in
        unique [
          "c"
          "a"
          "b"
          "a"
          "c"
        ] == [
          "c"
          "a"
          "b"
        ];
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

    # Test 4: findModulesForClass finds nixos modules
    findModulesForClassNixos = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test1 = {
                nixos = {
                  enable = true;
                };
              };
            }
            {
              config.substrate.modules.programs.test2 = {
                nixos = {
                  enable = false;
                };
              };
            }
          ];
          findModulesForClass = eval.config.substrate.lib.findModulesForClass;
        in
        lib.length (findModulesForClass "nixos" [ ]) == 2;
    };

    # Test 5: findModulesForClass filters modules without the class
    findModulesForClassFiltersOtherClasses = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test1 = {
                nixos = null;
                homeManager = {
                  config = { };
                };
              };
            }
            {
              config.substrate.modules.programs.test2 = {
                nixos = {
                  enable = true;
                };
              };
            }
          ];
          findModulesForClass = eval.config.substrate.lib.findModulesForClass;
        in
        lib.length (findModulesForClass "nixos" [ ]) == 1;
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
        hasClass "homeManager" == false;
    };

    # Test 8: extraArgsGenerator returns empty attrs with no generators
    extraArgsGeneratorEmpty = {
      check =
        let
          eval = evalSubstrate [ ];
          extraArgsGenerator = eval.config.substrate.lib.extraArgsGenerator;
          args = extraArgsGenerator {
            hostcfg = null;
            usercfg = null;
            pkgs = null;
            inputs = null;
          };
        in
        args == { };
    };

    # Test 9: extraArgsGenerator merges multiple generators
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
          args = extraArgsGenerator {
            hostcfg = null;
            usercfg = null;
            pkgs = null;
            inputs = null;
          };
        in
        args.foo == "bar" && args.baz == 42;
    };

    # Test 10: findModulesForClass includes generic modules for nixos
    findModulesForClassIncludesGenericForNixos = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test1 = {
                generic = {
                  shared = true;
                };
                nixos = null;
              };
            }
            {
              config.substrate.modules.programs.test2 = {
                generic = null;
                nixos = {
                  enable = true;
                };
              };
            }
          ];
          findModulesForClass = eval.config.substrate.lib.findModulesForClass;
        in
        lib.length (findModulesForClass "nixos" [ ]) == 2;
    };

    # Test 11: findModulesForClass includes generic modules for homeManager
    findModulesForClassIncludesGenericForHomeManager = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test1 = {
                generic = {
                  shared = true;
                };
                homeManager = null;
              };
            }
            {
              config.substrate.modules.programs.test2 = {
                generic = null;
                homeManager = {
                  config = { };
                };
              };
            }
          ];
          findModulesForClass = eval.config.substrate.lib.findModulesForClass;
        in
        lib.length (findModulesForClass "homeManager" [ ]) == 2;
    };

    # Test 12: findModulesForClass with both generic and specific modules
    findModulesForClassBothGenericAndSpecific = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test = {
                generic = {
                  shared = true;
                };
                nixos = {
                  specific = true;
                };
              };
            }
          ];
          findModulesForClass = eval.config.substrate.lib.findModulesForClass;
          result = findModulesForClass "nixos" [ ];
        in
        lib.length result == 2;
    };

    # Test 13: findModulesForClass for generic class does not double-include generic
    findModulesForClassGenericClassNoDoubleInclude = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test = {
                generic = {
                  shared = true;
                };
                nixos = null;
              };
            }
          ];
          findModulesForClass = eval.config.substrate.lib.findModulesForClass;
        in
        lib.length (findModulesForClass "generic" [ ]) == 1;
    };

    # Test 14: nameFromPath extracts name from file path
    nameFromPathFile = {
      check =
        let
          eval = evalSubstrate [ ];
          nameFromPath = eval.config.substrate.lib.nameFromPath;
        in
        nameFromPath "/foo/bar/baz.nix" == "baz";
    };

    # Test 15: nameFromPath extracts name from directory path
    nameFromPathDir = {
      check =
        let
          eval = evalSubstrate [ ];
          nameFromPath = eval.config.substrate.lib.nameFromPath;
        in
        nameFromPath "/foo/bar/baz" == "baz";
    };
  };
in
runTests "Lib Tests" tests
