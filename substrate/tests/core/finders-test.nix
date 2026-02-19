# Tests for substrate finders
# Run with: nix eval -f substrate/tests/core/finders-test.nix
{
  pkgs ? import <nixpkgs> { },
}:
let
  testLib = import ../lib.nix { inherit pkgs; };
  inherit (testLib) lib mkEvalSubstrate runTests;

  # Finders tests only need a minimal set of core modules
  evalSubstrate = mkEvalSubstrate [
    ../../core/settings.nix
    ../../core/lib.nix
    ../../core/modules.nix
    ../../core/finders.nix
  ];

  tests = {
    # Test 1: "all" finder exists
    allFinderExists = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.moduleFinders ? all;
    };

    # Test 2: "all" finder has find function
    allFinderHasFind = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.moduleFinders.all ? find;
    };

    # Test 3: "all" finder returns empty list with no modules
    allFinderEmptyModules = {
      check =
        let
          eval = evalSubstrate [ ];
          found = eval.config.substrate.moduleFinders.all.find [ ];
        in
        found == [ ];
    };

    # Test 4: "all" finder finds leaf modules
    allFinderFindsLeaves = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test = {
                nixos = { };
              };
            }
          ];
          found = eval.config.substrate.moduleFinders.all.find [ ];
        in
        lib.length found == 1;
    };

    # Test 5: "all" finder finds multiple modules
    allFinderFindsMultiple = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.git = {
                nixos = { };
              };
            }
            {
              config.substrate.modules.programs.vim = {
                nixos = { };
              };
            }
            {
              config.substrate.modules.hardware.audio = {
                nixos = { };
              };
            }
          ];
          found = eval.config.substrate.moduleFinders.all.find [ ];
        in
        lib.length found == 3;
    };

    # Test 6: "all" finder ignores intermediate nodes
    allFinderIgnoresIntermediates = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.editors.vim = {
                nixos = { };
              };
            }
          ];
          found = eval.config.substrate.moduleFinders.all.find [ ];
        in
        # Only vim should be found, not programs or editors
        lib.length found == 1;
    };

    # Test 7: "all" finder returns modules with nixos content
    allFinderReturnsContent = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test = {
                nixos = { }; # Any non-null value
              };
            }
          ];
          found = eval.config.substrate.moduleFinders.all.find [ ];
          module = builtins.head found;
        in
        # Module should have nixos attribute that is not null
        module ? nixos && module.nixos != null;
    };

    # Test 8: Default modulesFinder is "all"
    defaultModulesFinderIsAll = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.settings.modulesFinder == "all";
    };

    # Test 9: Custom finders can be registered
    customFinderRegistered = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.moduleFinders.custom = {
                find = _: [ ];
              };
            }
          ];
        in
        eval.config.substrate.moduleFinders ? custom;
    };

    # Test 10: Finder receives config argument
    finderReceivesConfig = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.moduleFinders.test = {
                # Custom finder accepts list of configs
                find = cfgs: if builtins.any (cfg: cfg ? testAttr) cfgs then [ "found" ] else [ ];
              };
            }
          ];
          found = eval.config.substrate.moduleFinders.test.find [ { testAttr = true; } ];
        in
        found == [ "found" ];
    };
  };
in
runTests "Finders Tests" tests
