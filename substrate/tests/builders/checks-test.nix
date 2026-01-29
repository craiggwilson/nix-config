# Tests for substrate configuration validation checks
# These tests verify the validation module can detect configuration issues
# Note: Some validations (like invalid module tags) are already caught by
# the type system at evaluation time, so we test the validation logic
# in isolation where possible.
{
  pkgs ? import <nixpkgs> { },
}:
let
  testLib = import ../lib.nix { inherit pkgs; };
  inherit (testLib) lib mkEvalSubstrate runTests;

  # Checks tests need extended core plus tags extension
  evalSubstrate = mkEvalSubstrate [
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
  ];

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
              config.substrate.users.alice = { };
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
in
runTests "Configuration Validation Tests" tests

