# Tests for substrate hosts and users
# Run with: nix eval -f substrate/tests/core/hosts-users-test.nix
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
        ../../core/hosts.nix
        ../../core/users.nix
      ] ++ modules;
    };

  tests = {
    # Test 1: Host can be defined with minimal config
    hostMinimalConfig = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.hosts.testhost = { };
            }
          ];
        in
        eval.config.substrate.hosts.testhost.name == "testhost";
    };

    # Test 2: Host name defaults to attribute name
    hostNameDefault = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.hosts.myserver = { };
            }
          ];
        in
        eval.config.substrate.hosts.myserver.name == "myserver";
    };

    # Test 3: Host can reference users
    hostReferencesUsers = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.alice = {
                fullName = "Alice";
                email = "alice@test.com";
                publicKey = null;
              };
              config.substrate.hosts.testhost = {
                users = [ "alice" ];
              };
            }
          ];
        in
        eval.config.substrate.hosts.testhost.users == [ "alice" ];
    };

    # Test 4: User can be defined with required fields
    userRequiredFields = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.bob = {
                fullName = "Bob Smith";
                email = "bob@test.com";
                publicKey = null;
              };
            }
          ];
        in
        eval.config.substrate.users.bob.fullName == "Bob Smith"
        && eval.config.substrate.users.bob.email == "bob@test.com";
    };

    # Test 5: User name defaults to attribute name
    userNameDefault = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.charlie = {
                fullName = "Charlie";
                email = "charlie@test.com";
                publicKey = null;
              };
            }
          ];
        in
        eval.config.substrate.users.charlie.name == "charlie";
    };

    # Test 6: User homeDirectory has sensible default
    userHomeDirectoryDefault = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.dave = {
                fullName = "Dave";
                email = "dave@test.com";
                publicKey = null;
              };
            }
          ];
        in
        eval.config.substrate.users.dave.homeDirectory == "/home/dave";
    };

    # Test 7: Multiple hosts can be defined
    multipleHosts = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.hosts.host1 = { };
              config.substrate.hosts.host2 = { };
              config.substrate.hosts.host3 = { };
            }
          ];
        in
        builtins.length (builtins.attrNames eval.config.substrate.hosts) == 3;
    };

    # Test 8: Multiple users can be defined
    multipleUsers = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.user1 = {
                fullName = "User 1";
                email = "user1@test.com";
                publicKey = null;
              };
              config.substrate.users.user2 = {
                fullName = "User 2";
                email = "user2@test.com";
                publicKey = null;
              };
            }
          ];
        in
        builtins.length (builtins.attrNames eval.config.substrate.users) == 2;
    };

    # Test 9: Empty hosts is valid
    emptyHosts = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.hosts == { };
    };

    # Test 10: Empty users is valid
    emptyUsers = {
      check =
        let
          eval = evalSubstrate [ ];
        in
        eval.config.substrate.users == { };
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
      Hosts & Users Tests
      ===================
      Tests: ${toString (lib.length (lib.attrValues results))}
      Passed: ${toString (lib.length passed)}
      Failed: ${toString (lib.length failed)}
      ${lib.concatMapStringsSep "\n" (r: "  ${r.name}: ${r.message}") (lib.attrValues results)}
    '';
}

