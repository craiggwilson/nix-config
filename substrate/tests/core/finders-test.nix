# Tests for substrate finders
# Run with: nix eval -f substrate/tests/core/finders-test.nix
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
      ] ++ modules;
    };

  tests = {
    # Test 1: "all" finder exists
    allFinderExists = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.finders ? all;
    };

    # Test 2: "all" finder has find function
    allFinderHasFind = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.finders.all ? find;
    };

    # Test 3: "all" finder returns empty list with no modules
    allFinderEmptyModules = {
      check =
        let
          eval = evalSubstrate [ ];
          found = eval.config.substrate.finders.all.find [ ];
        in
        found == [ ];
    };

    # Test 4: "all" finder finds leaf modules
    allFinderFindsLeaves = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test = { nixos = { }; };
            }
          ];
          found = eval.config.substrate.finders.all.find [ ];
        in
        lib.length found == 1;
    };

    # Test 5: "all" finder finds multiple modules
    allFinderFindsMultiple = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.modules.programs.git = { nixos = { }; }; }
            { config.substrate.modules.programs.vim = { nixos = { }; }; }
            { config.substrate.modules.hardware.audio = { nixos = { }; }; }
          ];
          found = eval.config.substrate.finders.all.find [ ];
        in
        lib.length found == 3;
    };

    # Test 6: "all" finder ignores intermediate nodes
    allFinderIgnoresIntermediates = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.modules.programs.editors.vim = { nixos = { }; }; }
          ];
          found = eval.config.substrate.finders.all.find [ ];
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
                nixos = { };  # Any non-null value
              };
            }
          ];
          found = eval.config.substrate.finders.all.find [ ];
          module = builtins.head found;
        in
        # Module should have nixos attribute that is not null
        module ? nixos && module.nixos != null;
    };

    # Test 8: Default finder is "all"
    defaultFinderIsAll = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.settings.finder == "all";
    };

    # Test 9: Custom finders can be registered
    customFinderRegistered = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.finders.custom = {
                find = _: [ ];
              };
            }
          ];
        in
        eval.config.substrate.finders ? custom;
    };

    # Test 10: Finder receives config argument
    finderReceivesConfig = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.finders.test = {
                # Custom finder accepts list of configs
                find = cfgs: if builtins.any (cfg: cfg ? testAttr) cfgs then [ "found" ] else [ ];
              };
            }
          ];
          found = eval.config.substrate.finders.test.find [ { testAttr = true; } ];
        in
        found == [ "found" ];
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
      Finders Tests
      =============
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';
}

