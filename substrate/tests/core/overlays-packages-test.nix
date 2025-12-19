# Tests for substrate overlays and packages
# Run with: nix eval -f substrate/tests/core/overlays-packages-test.nix
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
    # Test 1: Default overlays list is empty
    defaultOverlaysEmpty = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.settings.overlays == [ ];
    };

    # Test 2: Custom overlays can be added
    customOverlaysAdded = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.overlays = [
                (final: prev: { testPkg = null; })
              ];
            }
          ];
        in
        lib.length eval.config.substrate.settings.overlays == 1;
    };

    # Test 3: Multiple overlays can be added
    multipleOverlays = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.settings.overlays = [ (final: prev: { }) ]; }
            { config.substrate.settings.overlays = [ (final: prev: { }) ]; }
          ];
        in
        lib.length eval.config.substrate.settings.overlays == 2;
    };

    # Test 4: Packages overlay is callable (function or functor)
    packagesOverlayIsCallable = {
      check =
        let
          eval = evalSubstrate [ ];
          overlay = eval.config.substrate.overlays;
        in
        # Can be either a function or a functor (attrset with __functor)
        builtins.isFunction overlay || (builtins.isAttrs overlay && overlay ? __functor);
    };

    # Test 5: Default packages list is empty
    defaultPackagesEmpty = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.settings.packages == [ ];
    };

    # Test 6: Package namespace can be set
    packageNamespaceSet = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.settings.packageNamespace = "myns"; }
          ];
        in
        eval.config.substrate.settings.packageNamespace == "myns";
    };

    # Test 7: mkAllOverlays includes both packages overlay and custom overlays
    mkAllOverlaysComplete = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.overlays = [
                (final: prev: { })
                (final: prev: { })
              ];
            }
          ];
          mkAllOverlays = eval.config.substrate.lib.mkAllOverlays;
        in
        # Should have 3: 1 packages overlay + 2 custom
        lib.length mkAllOverlays == 3;
    };

    # Test 8: Packages overlay creates namespace
    packagesOverlayCreatesNamespace = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.settings.packageNamespace = "testns"; }
          ];
          overlay = eval.config.substrate.overlays;
          # Apply overlay to empty prev
          result = overlay pkgs { };
        in
        result ? testns;
    };

    # Test 9: mkPackages returns empty attrset with no packages
    mkPackagesEmpty = {
      check =
        let
          eval = evalSubstrate [ ];
          packages = eval.config.substrate.lib.mkPackages pkgs;
        in
        packages == { };
    };

    # Test 10: mkPackagesDerivationsOnly returns empty with no packages
    mkPackagesDerivationsOnlyEmpty = {
      check =
        let
          eval = evalSubstrate [ ];
          packages = eval.config.substrate.lib.mkPackagesDerivationsOnly pkgs;
        in
        packages == { };
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
      Overlays & Packages Tests
      =========================
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';
}

