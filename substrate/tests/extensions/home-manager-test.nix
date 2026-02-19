# Tests for substrate home-manager extension
# Run with: nix eval -f substrate/tests/extensions/home-manager-test.nix
{
  pkgs ? import <nixpkgs> { },
}:
let
  testLib = import ../lib.nix { inherit pkgs; };
  inherit (testLib)
    lib
    mkEvalSubstrate
    evalSubstrate
    runTests
    ;

  # Rename the base evaluator for clarity
  evalSubstrateBase = evalSubstrate;

  # Evaluate substrate with home-manager extension
  evalSubstrateWithHM = mkEvalSubstrate [
    ../../core
    ../../extensions/home-manager/default.nix
  ];

  tests = {
    # Test 1: homeManager class is not supported without extension
    homeManagerNotSupportedWithoutExtension = {
      check =
        let
          eval = evalSubstrateBase [ ];
          hasClass = eval.config.substrate.lib.hasClass;
        in
        hasClass "homeManager" == false;
    };

    # Test 2: homeManager class is supported with extension
    homeManagerSupportedWithExtension = {
      check =
        let
          eval = evalSubstrateWithHM [ ];
          hasClass = eval.config.substrate.lib.hasClass;
        in
        hasClass "homeManager" == true;
    };

    # Test 3: homeManagerModules option exists with extension
    homeManagerModulesOptionExists = {
      check =
        let
          eval = evalSubstrateWithHM [ ];
        in
        eval.config.substrate.settings ? homeManagerModules;
    };

    # Test 4: homeManagerModules defaults to empty list
    homeManagerModulesDefaultEmpty = {
      check =
        let
          eval = evalSubstrateWithHM [ ];
        in
        eval.config.substrate.settings.homeManagerModules == [ ];
    };

    # Test 5: Module can have homeManager content with extension
    moduleCanHaveHomeManager = {
      check =
        let
          eval = evalSubstrateWithHM [
            {
              config.substrate.modules.programs.test = {
                homeManager = {
                  programs.git.enable = true;
                };
              };
            }
          ];
        in
        eval.config.substrate.modules.programs.test.homeManager != null;
    };

    # Test 6: findModulesForClass works for homeManager
    findModulesForClassHomeManager = {
      check =
        let
          eval = evalSubstrateWithHM [
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
                nixos = { };
                homeManager = null;
              };
            }
          ];
          findModulesForClass = eval.config.substrate.lib.findModulesForClass;
        in
        lib.length (findModulesForClass "homeManager" [ ]) == 1;
    };

    # Test 7: Both nixos and homeManager can coexist
    nixosAndHomeManagerCoexist = {
      check =
        let
          eval = evalSubstrateWithHM [
            {
              config.substrate.modules.programs.git = {
                nixos = {
                  programs.git.enable = true;
                };
                homeManager = {
                  programs.git.userName = "test";
                };
              };
            }
          ];
          mod = eval.config.substrate.modules.programs.git;
        in
        mod.nixos != null && mod.homeManager != null;
    };

    # Test 8: supportedClasses includes both nixos and homeManager
    supportedClassesIncludesBoth = {
      check =
        let
          eval = evalSubstrateWithHM [ ];
          classes = eval.config.substrate.settings.supportedClasses;
        in
        lib.elem "nixos" classes && lib.elem "homeManager" classes;
    };
  };
in
runTests "Home-Manager Extension Tests" tests
