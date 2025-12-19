# Tests for substrate.modules tree type
# Run with: nix eval -f substrate/tests/modules-test.nix
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

  # Evaluate a substrate configuration with the given modules
  evalSubstrate =
    modules:
    lib.evalModules {
      modules = [
        ../../core/settings.nix
        ../../core/modules.nix
        ../../core/finders.nix
      ]
      ++ modules;
    };

  tests = {
    # Test 1: Basic leaf node with nixos module
    basicLeafNode = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test = {
                nixos = { };
              };
            }
          ];
        in
        eval.config.substrate.modules.programs.test ? nixos;
    };

    # Test 2: Nested tree structure
    nestedTreeStructure = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.hardware.gpu.nvidia = {
                nixos = { };
              };
            }
          ];
        in
        eval.config.substrate.modules.hardware.gpu.nvidia ? nixos;
    };

    # Test 3: Multiple leaves at different levels
    multipleLeavesAtDifferentLevels = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.git = {
                nixos = { };
                homeManager = { };
              };
            }
            {
              config.substrate.modules.hardware.audio = {
                nixos = { };
              };
            }
          ];
        in
        eval.config.substrate.modules.programs.git ? nixos
        && eval.config.substrate.modules.programs.git ? homeManager
        && eval.config.substrate.modules.hardware.audio ? nixos;
    };

    # Test 4: Custom options at intermediate level (the key fix)
    customOptionsAtIntermediateLevel = {
      check =
        let
          eval = evalSubstrate [
            {
              # Define custom option at hardware.monitors
              options.substrate.modules.hardware.monitors = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
              config.substrate.modules.hardware.monitors.enable = true;
            }
            {
              # Define a leaf node under hardware.monitors
              config.substrate.modules.hardware.monitors.primary = {
                nixos = { };
              };
            }
          ];
        in
        eval.config.substrate.modules.hardware.monitors.enable == true
        && eval.config.substrate.modules.hardware.monitors.primary ? nixos;
    };

    # Test 5: Merging config from multiple modules
    mergingFromMultipleModules = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.vim = {
                nixos = { };
              };
            }
            {
              config.substrate.modules.programs.vim = {
                homeManager = { };
              };
            }
          ];
        in
        eval.config.substrate.modules.programs.vim ? nixos
        && eval.config.substrate.modules.programs.vim ? homeManager;
    };

    # Test 6: Deep nesting (5+ levels)
    deepNesting = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.a.b.c.d.e.f = {
                nixos = { };
              };
            }
          ];
        in
        eval.config.substrate.modules.a.b.c.d.e.f ? nixos;
    };

    # Test 7: collectSubstrateModules finds leaf nodes (only nodes with content)
    collectFindsLeaves = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.git = {
                nixos = { };
              };
            }
            {
              config.substrate.modules.hardware.audio = {
                nixos = { };
              };
            }
          ];
          found = eval.config.substrate.finders.all.find [ ];
        in
        lib.length found == 2 && lib.all (m: m ? nixos && m.nixos != null) found;
    };

    # Test 8: Leaf options exist but default to null (nixos is the default supported class)
    leafOptionsDefaultToNull = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.test = { };
            }
          ];
        in
        # Only nixos is in supportedClasses by default (without home-manager extension)
        eval.config.substrate.modules.programs.test ? nixos
        && eval.config.substrate.modules.programs.test.nixos == null;
    };

    # Test 9: Multiple custom options at different levels
    multipleCustomOptionsAtDifferentLevels = {
      check =
        let
          eval = evalSubstrate [
            {
              options.substrate.modules.hardware = {
                hardwareEnabled = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
              config.substrate.modules.hardware.hardwareEnabled = true;
            }
            {
              options.substrate.modules.hardware.monitors = {
                monitorsEnabled = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
              config.substrate.modules.hardware.monitors.monitorsEnabled = true;
            }
            {
              config.substrate.modules.hardware.monitors.primary = {
                nixos = { };
              };
            }
          ];
        in
        eval.config.substrate.modules.hardware.hardwareEnabled == true
        && eval.config.substrate.modules.hardware.monitors.monitorsEnabled == true
        && eval.config.substrate.modules.hardware.monitors.primary ? nixos;
    };

    # Test 10: Empty tree is valid
    emptyTreeIsValid = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.modules == { };
    };

    # Test 11: Type checking - tags must be a list (positive test)
    typeCheckingValidTags = {
      check =
        let
          eval = lib.evalModules {
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
              {
                config.substrate.settings.tags = [
                  "core"
                  "other"
                ];
              }
              {
                config.substrate.modules.programs.test = {
                  nixos = { };
                  tags = [ "core" ]; # Valid - is a list
                };
              }
            ];
          };
        in
        eval.config.substrate.modules.programs.test.tags == [ "core" ];
    };

    # Test 12: Intermediate nodes don't get collected
    intermediateNodesNotCollected = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.editors.vim = {
                nixos = { };
              };
            }
          ];
          found = eval.config.substrate.finders.all.find [ ];
        in
        # Only the vim leaf should be collected, not programs or editors
        lib.length found == 1;
    };

    # Test 13: Both nixos and homeManager can be set
    bothClassesCanBeSet = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.modules.programs.git = {
                nixos = {
                  programs.git.enable = true;
                };
                homeManager = {
                  programs.git.enable = true;
                };
              };
            }
          ];
        in
        eval.config.substrate.modules.programs.git.nixos != null
        && eval.config.substrate.modules.programs.git.homeManager != null;
    };

    # Test 14: Extra module options work (like tags from the extension)
    extraModuleOptionsWork = {
      check =
        let
          eval = lib.evalModules {
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
              {
                config.substrate.settings.tags = [
                  "core"
                  "extra"
                ];
              }
              {
                config.substrate.modules.programs.test = {
                  nixos = { };
                  tags = [ "core" ];
                };
              }
            ];
          };
        in
        eval.config.substrate.modules.programs.test.tags == [ "core" ];
    };

    # Test 15: Invalid tags are rejected when finder is used
    invalidTagsRejected = {
      check =
        let
          eval = lib.evalModules {
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
              {
                config.substrate.settings.tags = [
                  "core"
                  "other"
                ];
              }
              {
                config.substrate.modules.programs.test = {
                  nixos = { };
                  tags = [ "invalid-tag" ]; # This tag is not in settings.tags
                };
              }
              {
                config.substrate.users.testuser = {
                  fullName = "Test User";
                  email = "test@test.com";
                  publicKey = null;
                  tags = [ "core" ];
                };
              }
            ];
          };
          # Attempt to use the finder - this should fail because "invalid-tag" is not valid
          result = builtins.tryEval (
            builtins.deepSeq (eval.config.substrate.finders.by-tags.find [ eval.config.substrate.users.testuser ]) true
          );
        in
        # The evaluation should fail (result.success should be false)
        !result.success;
    };

    # Test 16: Valid tags work correctly with finder (modules are filtered properly)
    validTagsFilterCorrectly = {
      check =
        let
          eval = lib.evalModules {
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
              {
                config.substrate.settings.tags = [
                  "core"
                  "other"
                ];
              }
              {
                config.substrate.modules.programs.included = {
                  nixos = { };
                  tags = [ "core" ]; # Should be included
                };
              }
              {
                config.substrate.modules.programs.excluded = {
                  nixos = { };
                  tags = [ "other" ]; # Should be excluded (user only has "core")
                };
              }
              {
                config.substrate.users.testuser = {
                  fullName = "Test User";
                  email = "test@test.com";
                  publicKey = null;
                  tags = [ "core" ];
                };
              }
            ];
          };
          found = eval.config.substrate.finders.by-tags.find [ eval.config.substrate.users.testuser ];
        in
        # Only one module should be found (the one with "core" tag)
        lib.length found == 1;
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
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';
}
