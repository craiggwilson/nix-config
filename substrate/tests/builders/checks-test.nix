# Tests for substrate configuration validation checks
# These tests verify the validation module can detect configuration issues
# Note: Some validations (like invalid module tags) are already caught by
# the type system at evaluation time, so we test the validation logic
# in isolation where possible.
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

  # Evaluate substrate configuration
  evalSubstrate =
    modules:
    lib.evalModules {
      modules = [
        ../../core/settings.nix
        ../../core/lib.nix
        ../../core/modules.nix
        ../../core/finders.nix
        ../../core/hosts.nix
        ../../core/users.nix
        ../../core/overlays.nix
        ../../core/packages.nix
        ../../core/checks.nix
        ../../extensions/tags/default.nix
      ] ++ modules;
    };

  tests = {
    # Test 1: Valid config with modules using valid tags
    validModuleTags = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [ "core" "gui" ];
              config.substrate.modules.programs.test = {
                nixos = { };
                tags = [ "core" ];
              };
            }
          ];
        in
        eval.config.substrate.modules.programs.test.tags == [ "core" ];
    };

    # Test 2: Valid user tags are accepted
    validUserTags = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [ "desktop" "laptop" ];
              config.substrate.users.alice = {
                fullName = "Alice";
                email = "alice@test.com";
                publicKey = null;
                tags = [ "desktop" ];
              };
            }
          ];
        in
        eval.config.substrate.users.alice.tags == [ "desktop" ];
    };

    # Test 3: Host can reference valid users
    hostWithValidUsers = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.alice = {
                fullName = "Alice";
                email = "alice@test.com";
                publicKey = null;
              };
              config.substrate.hosts.myhost = {
                users = [ "alice" ];
              };
            }
          ];
        in
        eval.config.substrate.hosts.myhost.users == [ "alice" ];
    };

    # Test 4: Host referencing invalid user fails at type check
    hostWithInvalidUserFails = {
      check =
        let
          result = builtins.tryEval (
            let
              eval = evalSubstrate [
                {
                  config.substrate.hosts.myhost = {
                    users = [ "nonexistent" ];
                  };
                }
              ];
            in
            builtins.deepSeq eval.config.substrate.hosts.myhost.users true
          );
        in
        # Should fail because "nonexistent" is not a valid user
        !result.success;
    };

    # Test 5: Multiple modules with valid tags all work
    multipleModulesValidTags = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [ "core" "gui" "cli" ];
              config.substrate.modules.programs.mod1 = { nixos = { }; tags = [ "core" ]; };
              config.substrate.modules.programs.mod2 = { nixos = { }; tags = [ "gui" ]; };
              config.substrate.modules.programs.mod3 = { nixos = { }; tags = [ "cli" ]; };
            }
          ];
          allMods = eval.config.substrate.finders.all.find [ ];
        in
        lib.length allMods == 3;
    };

    # Test 6: Modules with no tags have empty tags list
    modulesWithNoTags = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [ "core" ];
              config.substrate.modules.programs.test = { nixos = { }; };
            }
          ];
        in
        eval.config.substrate.modules.programs.test.tags == [ ];
    };

    # Test 7: Supported classes are correct
    supportedClassesCorrect = {
      check =
        let
          eval = evalSubstrate [ ];
          classes = eval.config.substrate.settings.supportedClasses;
        in
        lib.elem "nixos" classes;
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
      Configuration Validation Tests
      ==============================
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';
}

