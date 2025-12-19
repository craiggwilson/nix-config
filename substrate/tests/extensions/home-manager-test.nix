# Tests for substrate home-manager extension
# Run with: nix eval -f substrate/tests/extensions/home-manager-test.nix
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

  # Evaluate substrate without home-manager extension
  evalSubstrateBase =
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

  # Evaluate substrate with home-manager extension
  evalSubstrateWithHM =
    modules:
    lib.evalModules {
      modules = [
        ../../core/settings.nix
        ../../core/lib.nix
        ../../core/modules.nix
        ../../core/finders.nix
        ../../core/overlays.nix
        ../../core/packages.nix
        ../../extensions/home-manager/default.nix
      ] ++ modules;
    };

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
                homeManager = { programs.git.enable = true; };
              };
            }
          ];
        in
        eval.config.substrate.modules.programs.test.homeManager != null;
    };

    # Test 6: extractClassModules works for homeManager
    extractClassModulesHomeManager = {
      check =
        let
          eval = evalSubstrateWithHM [ ];
          extractClassModules = eval.config.substrate.lib.extractClassModules;
          mods = [
            { nixos = null; homeManager = { config = { }; }; }
            { nixos = { }; homeManager = null; }
          ];
        in
        lib.length (extractClassModules "homeManager" mods) == 1;
    };

    # Test 7: Both nixos and homeManager can coexist
    nixosAndHomeManagerCoexist = {
      check =
        let
          eval = evalSubstrateWithHM [
            {
              config.substrate.modules.programs.git = {
                nixos = { programs.git.enable = true; };
                homeManager = { programs.git.userName = "test"; };
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
      Home-Manager Extension Tests
      ============================
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';
}

