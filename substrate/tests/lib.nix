# Shared test utilities for substrate tests
# Import with: testLib = import ../lib.nix { inherit pkgs; };
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
        {
          inherit name;
          success = true;
          message = "PASS";
        }
      else
        {
          inherit name;
          success = false;
          message = "FAIL: check returned false";
        }
    else
      {
        inherit name;
        success = false;
        message = "FAIL: evaluation error";
      };

  # Core modules required by most tests
  coreModules = [
    ../core/settings.nix
    ../core/lib.nix
    ../core/modules.nix
    ../core/finders.nix
    ../core/overlays.nix
    ../core/packages.nix
  ];

  # Extended core modules (includes hosts, users, checks)
  extendedCoreModules = coreModules ++ [
    ../core/hosts.nix
    ../core/users.nix
    ../core/checks.nix
  ];

  # Create an evalSubstrate function with specific base modules
  mkEvalSubstrate =
    baseModules: extraModules:
    lib.evalModules {
      modules = baseModules ++ extraModules;
    };

  # Standard evalSubstrate with core modules only
  evalSubstrate = mkEvalSubstrate coreModules;

  # Extended evalSubstrate with hosts/users/checks
  evalSubstrateExtended = mkEvalSubstrate extendedCoreModules;

  # Generate summary from test results
  mkSummary =
    title: results:
    let
      passed = lib.filter (r: r.success) (lib.attrValues results);
      failed = lib.filter (r: !r.success) (lib.attrValues results);
    in
    ''
      ${title}
      ${"=" * (lib.stringLength title)}
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';

  # Run all tests and return standard result structure
  runTests =
    title: tests:
    let
      results = lib.mapAttrs runTest tests;
      allPassed = lib.all (r: r.success) (lib.attrValues results);
    in
    {
      inherit results allPassed;
      summary = mkSummary title results;
    };
in
{
  inherit
    lib
    runTest
    coreModules
    extendedCoreModules
    mkEvalSubstrate
    evalSubstrate
    evalSubstrateExtended
    mkSummary
    runTests
    ;
}

