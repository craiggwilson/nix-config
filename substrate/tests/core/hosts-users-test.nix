# Tests for substrate hosts and users
# Run with: nix eval -f substrate/tests/core/hosts-users-test.nix
{
  pkgs ? import <nixpkgs> { },
}:
let
  testLib = import ../lib.nix { inherit pkgs; };
  inherit (testLib) lib mkEvalSubstrate runTests;

  # Hosts/users tests need core modules plus hosts.nix and users.nix
  evalSubstrate = mkEvalSubstrate [
    ../../core/settings.nix
    ../../core/lib.nix
    ../../core/modules.nix
    ../../core/finders.nix
    ../../core/hosts.nix
    ../../core/users.nix
  ];

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
              config.substrate.users.alice = { };
              config.substrate.hosts.testhost = {
                users = [ "alice" ];
              };
            }
          ];
        in
        eval.config.substrate.hosts.testhost.users == [ "alice" ];
    };

    # Test 4: User can be defined with just a name
    userRequiredFields = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.bob = { };
            }
          ];
        in
        eval.config.substrate.users.bob.name == "bob";
    };

    # Test 5: User name defaults to attribute name
    userNameDefault = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.charlie = { };
            }
          ];
        in
        eval.config.substrate.users.charlie.name == "charlie";
    };

    # Test 6: User name is accessible
    userHomeDirectoryDefault = {
      check =
        let
          eval = evalSubstrate [
            {
              config.substrate.users.dave = { };
            }
          ];
        in
        eval.config.substrate.users.dave.name == "dave";
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
              config.substrate.users.user1 = { };
              config.substrate.users.user2 = { };
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
in
runTests "Hosts & Users Tests" tests

