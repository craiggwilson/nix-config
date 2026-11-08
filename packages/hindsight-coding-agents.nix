{
  substrate.packages.hindsight-coding-agents =
    { lib, pkgs, ... }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = "hindsight-coding-agents";
      version = "0.8.6";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@vectorize-io/hindsight-coding-agents/-/hindsight-coding-agents-0.8.6.tgz";
        hash = "sha256-4XoPGhyT3gpcy39uXSFA73q6wseUMIhZwzvL1IFLGVQ=";
      };
      sourceRoot = "package";

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        mkdir -p "$out/lib/node_modules/@vectorize-io/hindsight-coding-agents"
        cp -R . "$out/lib/node_modules/@vectorize-io/hindsight-coding-agents"
      '';

      meta = {
        description = "Hindsight automatic project memory plugin for OpenCode";
        homepage = "https://hindsight.vectorize.io/sdks/integrations/coding-agents";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
      };
    };
}
