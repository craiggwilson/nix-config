{ lib, pkgs, ... }:
let
  version = "0.2.10";

  src = pkgs.fetchFromGitHub {
    owner = "antongulin";
    repo = "opencode-skill-creator";
    tag = "v${version}";
    hash = "sha256-N/DyGkvB96c5qdcibDB64LNIdvTWbM2fh3PHl5mU+48=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-skill-creator";
  inherit version src;

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/opencode-skill-creator

    cp -r plugin/* $out/lib/opencode-skill-creator/

    runHook postInstall
  '';

  passthru = {
    pluginDir = "${placeholder "out"}/lib/opencode-skill-creator";
  };

  meta = {
    description = "OpenCode plugin for skill creation and optimization";
    homepage = "https://github.com/antongulin/opencode-skill-creator";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
