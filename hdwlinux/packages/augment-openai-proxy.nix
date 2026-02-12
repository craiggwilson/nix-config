{ lib, pkgs, ... }:
pkgs.buildNpmPackage {
  pname = "augment-openai-proxy";
  version = "1.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "craiggwilson";
    repo = "augment-opencode";
    rev = "ee16e1bc7210cfd37dc96220e2a231e46401bc25";
    hash = "sha256-s9XFcv0lks5393AKiGTukE6JjnDBdYOo7svClLdSn28=";
  };

  npmDepsHash = "sha256-kkkX1TAJkVzCGnPWuS0j3Ew526UDVF7f1x3NKsBnkwc=";

  # Use Node.js 24 as required by package.json
  nodejs = pkgs.nodejs_24;

  postInstall = ''
    mv $out/bin/auggie-wrapper $out/bin/augment-openai-proxy
  '';

  meta = {
    description = "OpenAI-compatible API proxy for Augment Code backends";
    homepage = "https://github.com/craiggwilson/augment-opencode";
    license = lib.licenses.mit;
    mainProgram = "augment-openai-proxy";
  };
}
