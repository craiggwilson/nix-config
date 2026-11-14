{
  substrate.packages.critty =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # Use the checksummed release binaries: upstream requires Go 1.27.2 to build,
      # newer than the Go toolchain in this flake's nixpkgs input.
      version = "1.11.2";
      assets = {
        aarch64-darwin = {
          name = "darwin_arm64";
          hash = "sha256-YFntRkdL2HW4gAehPKEzLGhpPS83vvlqWvY0icziekE=";
        };
        aarch64-linux = {
          name = "linux_arm64";
          hash = "sha256-DcZk1j9BOn1H8ihEieth8fdgjNuR53L7V5Tov7E7rmU=";
        };
        x86_64-darwin = {
          name = "darwin_amd64";
          hash = "sha256-Dyb+l6Bs5wg01AVbJZEpnnabLoqmHX6syz/qURvo2TU=";
        };
        x86_64-linux = {
          name = "linux_amd64";
          hash = "sha256-rl+JMrRMhPwxIgOjcB42XwJZ9XgIP2RND93Nf8IUAvA=";
        };
      };
      asset =
        assets.${pkgs.stdenv.hostPlatform.system}
          or (throw "critty: no release asset for ${pkgs.stdenv.hostPlatform.system}");
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "critty";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/crittylabs/critty/releases/download/v${version}/critty_${asset.name}.tar.gz";
        inherit (asset) hash;
      };

      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.gnutar
        pkgs.gzip
      ];

      installPhase = ''
        runHook preInstall
        tar -xzf "$src"
        install -Dm 0755 critty $out/bin/critty
        runHook postInstall
      '';

      meta = {
        description = "Terminal UI for reviewing code changes and documents with coding agents";
        homepage = "https://github.com/crittylabs/critty";
        license = lib.licenses.mit;
        mainProgram = "critty";
        platforms = builtins.attrNames assets;
      };
    };
}
