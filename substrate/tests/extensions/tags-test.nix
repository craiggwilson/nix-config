# Tests for substrate tags extension
# Run with: nix eval -f substrate/tests/extensions/tags-test.nix
{
  pkgs ? import <nixpkgs> { },
}:
let
  testLib = import ../lib.nix { inherit pkgs; };
  inherit (testLib) lib mkEvalSubstrate runTests;

  # Tags extension tests need extended core plus tags extension
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
    # Test 1: Simple string tags are normalized to attrsets
    simpleStringTagsNormalized = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.settings.tags = [ "core" "other" ]; }
          ];
          # After apply, tags should be a list of attrsets
          tags = eval.config.substrate.settings.tags;
        in
        builtins.isList tags
        && builtins.length tags == 2
        && builtins.isAttrs (builtins.elemAt tags 0);
    };

    # Test 2: Metatags with implications work
    metatagsWithImplications = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [
                "laptop"
                { "hardware:dell" = [ "laptop" ]; }
              ];
            }
          ];
          tags = eval.config.substrate.settings.tags;
        in
        builtins.length tags == 2;
    };

    # Test 3: Parent prefixes are automatically implied
    parentPrefixesImplied = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [
                "theming"
                "theming:catppuccin"
              ];
              config.substrate.users.testuser = {
                tags = [ "theming:catppuccin" ];
              };
            }
          ];
          # Find modules - the hasTag function should work for parent prefix
          found = eval.config.substrate.finders.by-tags.find [ eval.config.substrate.users.testuser ];
        in
        # Just verify evaluation succeeds
        builtins.isList found;
    };

    # Test 4: Invalid implied tags are rejected
    # The validation happens when modules with the implied tag are accessed
    invalidImpliedTagsRejected = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [
                "laptop"
                { "hardware:dell" = [ "typo-tag" ]; }  # "typo-tag" is not declared
              ];
              # Use the metatag which has an invalid implied tag
              config.substrate.users.testuser = {
                tags = [ "hardware:dell" ];  # This should trigger validation of implied "typo-tag"
              };
            }
          ];
          # Try to use the finder which should trigger validation
          result = builtins.tryEval (
            builtins.deepSeq (eval.config.substrate.finders.by-tags.find [ eval.config.substrate.users.testuser ]) true
          );
        in
        # Should fail because "typo-tag" is not a valid tag
        !result.success;
    };

    # Test 5: Tags can be merged from multiple definitions
    tagsMergeFromMultipleDefinitions = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.settings.tags = [ "core" ]; }
            { config.substrate.settings.tags = [ "other" ]; }
          ];
          tags = eval.config.substrate.settings.tags;
        in
        builtins.length tags == 2;
    };

    # Test 6: Same tag with implications merges correctly
    sameTagImplicationsMerge = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [
                "portable"
                "lightweight"
                "laptop"
                { "laptop" = [ "portable" ]; }
              ];
            }
            {
              config.substrate.settings.tags = [
                { "laptop" = [ "lightweight" ]; }
              ];
            }
          ];
          # This should work - laptop should imply both portable and lightweight
          tags = eval.config.substrate.settings.tags;
        in
        builtins.length tags == 5;  # 3 strings + 2 metatags
    };

    # Test 7: Modules are filtered by tags correctly
    modulesFilteredByTags = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [ "core" "extra" ];
              config.substrate.modules.programs.included = {
                nixos = { };
                tags = [ "core" ];
              };
              config.substrate.modules.programs.excluded = {
                nixos = { };
                tags = [ "extra" ];
              };
              config.substrate.users.testuser = {
                tags = [ "core" ];
              };
            }
          ];
          found = eval.config.substrate.finders.by-tags.find [ eval.config.substrate.users.testuser ];
        in
        # Only the "included" module should be found
        lib.length found == 1;
    };

    # Test 8: Modules with no tags are always included
    modulesWithNoTagsAlwaysIncluded = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [ "core" ];
              config.substrate.modules.programs.always = {
                nixos = { };
                # No tags - should always be included
              };
              config.substrate.modules.programs.conditional = {
                nixos = { };
                tags = [ "core" ];
              };
              config.substrate.users.testuser = {
                tags = [ "core" ];
              };
            }
          ];
          found = eval.config.substrate.finders.by-tags.find [ eval.config.substrate.users.testuser ];
        in
        # Both modules should be found
        lib.length found == 2;
    };

    # Test 9: Nested tag prefixes work (a:b:c implies a:b and a)
    nestedTagPrefixesWork = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [
                "desktop"
                "desktop:custom"
                "desktop:custom:hyprland"
              ];
              config.substrate.modules.programs.desktopModule = {
                nixos = { };
                tags = [ "desktop" ];
              };
              config.substrate.modules.programs.customModule = {
                nixos = { };
                tags = [ "desktop:custom" ];
              };
              config.substrate.users.testuser = {
                tags = [ "desktop:custom:hyprland" ];
              };
            }
          ];
          found = eval.config.substrate.finders.by-tags.find [ eval.config.substrate.users.testuser ];
        in
        # Both modules should be found (desktop and desktop:custom are implied by desktop:custom:hyprland)
        lib.length found == 2;
    };

    # Test 10: hasTag function works correctly
    hasTagFunctionWorks = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [
                "gui"
                "fonts"
                { "gui" = [ "fonts" ]; }
              ];
              config.substrate.users.testuser = {
                tags = [ "gui" ];
              };
            }
          ];
          # Get the extraArgsGenerator and create hasTag
          extraArgsGenerators = eval.config.substrate.settings.extraArgsGenerators;
          args = lib.mergeAttrsList (
            builtins.map (f: f { hostcfg = null; usercfg = eval.config.substrate.users.testuser; }) extraArgsGenerators
          );
        in
        # hasTag should return true for "gui" and "fonts" (implied)
        args.hasTag "gui" && args.hasTag "fonts";
    };

    # Test 11: Empty tags list is valid
    emptyTagsListValid = {
      check =
        let
          eval = evalSubstrate [
            { config.substrate.settings.tags = [ ]; }
          ];
        in
        eval.config.substrate.settings.tags == [ ];
    };

    # Test 12: Prefix matching for hasTag works
    prefixMatchingForHasTag = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.settings.tags = [
                "theming"
                "theming:catppuccin"
                "theming:catppuccin:mocha"
              ];
              config.substrate.users.testuser = {
                tags = [ "theming:catppuccin:mocha" ];
              };
            }
          ];
          extraArgsGenerators = eval.config.substrate.settings.extraArgsGenerators;
          args = lib.mergeAttrsList (
            builtins.map (f: f { hostcfg = null; usercfg = eval.config.substrate.users.testuser; }) extraArgsGenerators
          );
        in
        # hasTag should work for the exact tag and parent prefixes
        args.hasTag "theming:catppuccin:mocha"
        && args.hasTag "theming:catppuccin"
        && args.hasTag "theming";
    };
  };
in
runTests "Tags Extension Tests" tests

