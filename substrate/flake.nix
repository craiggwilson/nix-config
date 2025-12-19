{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    (import ./.)
    // {
      checks = forAllSystems (
        pkgs:
        let
          mkTest =
            name: testFile:
            let
              testResults = import testFile { inherit pkgs; };
            in
            pkgs.runCommand "substrate-${name}" { } ''
              if ${pkgs.lib.boolToString testResults.allPassed}; then
                echo "All tests passed!"
                echo "${testResults.summary}"
                touch $out
              else
                echo "Tests failed!"
                echo "${testResults.summary}"
                exit 1
              fi
            '';
        in
        {
          # Core tests
          core-modules-test = mkTest "modules-test" ./tests/core/modules-test.nix;
          core-lib-test = mkTest "lib-test" ./tests/core/lib-test.nix;
          core-hosts-users-test = mkTest "hosts-users-test" ./tests/core/hosts-users-test.nix;
          core-overlays-packages-test = mkTest "overlays-packages-test" ./tests/core/overlays-packages-test.nix;
          core-finders-test = mkTest "finders-test" ./tests/core/finders-test.nix;

          # Extension tests
          extensions-tags-test = mkTest "tags-test" ./tests/extensions/tags-test.nix;
          extensions-home-manager-test = mkTest "home-manager-test" ./tests/extensions/home-manager-test.nix;

          # Builder tests
          builders-checks-test = mkTest "checks-test" ./tests/builders/checks-test.nix;
        }
      );
    };
}
