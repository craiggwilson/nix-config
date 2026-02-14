{ lib, pkgs, ... }:
let
  # We treat the opencode workspace as a Bun/TypeScript monorepo and build
  # it once, then expose individual plugin packages from the built artefacts.
  version = "0.1.0";

  src = ./.;

  buildWorkspace = pkgs.stdenv.mkDerivation {
    pname = "opencode-plugins-suite";
    inherit version src;

    nativeBuildInputs = [
      pkgs.bun
      pkgs.nodejs
    ];

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR

      # Ensure tsc uses Nix's node
      if [ -f node_modules/.bin/tsc ]; then
        substituteInPlace node_modules/.bin/tsc \
          --replace-fail "/usr/bin/env node" "${lib.getExe pkgs.nodejs}" || true
      fi

      bun run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r core program-planner project-planner work-executor package.json $out/

      runHook postInstall
    '';
  };
in
{
  # Expose the fully-built workspace tree for downstream use. Individual
  # plugin packages are defined as separate derivations elsewhere that
  # reference this build output.
  opencode-plugins-suite = buildWorkspace // {
    meta = {
      description = "OpenCode Planning & Execution Plugin Suite (built workspace)";
      homepage = "https://hdwlinux/nix-config";
      license = lib.licenses.mit;
    };
  };

  passthru = {
    inherit buildWorkspace;
  };
}
