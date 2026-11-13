{
  substrate.packages.plannotator =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # Upstream ships one self-contained executable per platform in each
      # GitHub release. To update: bump version, then refresh these hashes
      # from the release's .sha256 sidecars
      # (nix hash convert --to sri --hash-algo sha256 <hex>).
      asset =
        {
          x86_64-linux = "linux-x64";
          aarch64-linux = "linux-arm64";
          aarch64-darwin = "darwin-arm64";
        }
        .${pkgs.stdenv.hostPlatform.system}
          or (throw "plannotator: no release asset for ${pkgs.stdenv.hostPlatform.system}");

      hashes = {
        linux-x64 = "sha256-Bn9cWdo2tgvc4zDSjrKUhPX0CeYCiXi2IGGIMpaCD7A=";
        linux-arm64 = "sha256-PQ9YBX7Q79eHsSbSnyxX0ASDZSbiNOAQp46fp7leicY=";
        darwin-arm64 = "sha256-43OSVjP+mYbomLtT3/wmoOZkURFj4mRsHiZV+/Zdqco=";
      };
    in
    pkgs.stdenvNoCC.mkDerivation rec {
      pname = "plannotator";
      version = "0.28.62";

      src = pkgs.fetchurl {
        url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-${asset}";
        hash = hashes.${asset};
      };

      dontUnpack = true;

      # The ELF must stay untouched: Bun embeds the app payload after it, and
      # patchelf --set-interpreter shifts those offsets, reducing the binary
      # to a bare `bun`. The interpreter stays /lib64/ld-linux-*.so, which
      # NixOS provides; the binary's only dynamic dependencies are glibc's
      # own libraries, which that loader resolves itself.
      installPhase = ''
        runHook preInstall
        install -Dm 0755 $src $out/bin/plannotator
        runHook postInstall
      '';

      meta = {
        description = "Local, browser-based review surface for AI coding agent plans and code";
        homepage = "https://plannotator.ai";
        license = with lib.licenses; [
          asl20
          mit
        ];
        mainProgram = "plannotator";
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
      };
    };
}
