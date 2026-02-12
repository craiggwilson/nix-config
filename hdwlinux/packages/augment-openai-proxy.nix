{ lib, pkgs, ... }:
pkgs.buildNpmPackage {
  pname = "augment-openai-proxy";
  version = "1.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "hletrd";
    repo = "augment-opencode";
    rev = "0c7722c902777dfef53546a7cbdd56764e654b5c";
    hash = "sha256-U3F/8Ixq2yO+Eo+d2AN9+bMTnJr+JuwmuwWhxH1YOHw=";
  };

  npmDepsHash = "sha256-kkkX1TAJkVzCGnPWuS0j3Ew526UDVF7f1x3NKsBnkwc=";

  # Use Node.js 24 as required by package.json
  nodejs = pkgs.nodejs_24;

  postInstall = ''
    mv $out/bin/auggie-wrapper $out/bin/augment-openai-proxy
  '';

  meta = {
    description = "OpenAI-compatible API proxy for Augment Code backends";
    homepage = "https://github.com/hletrd/augment-opencode";
    license = lib.licenses.mit;
    mainProgram = "augment-openai-proxy";
  };
}

