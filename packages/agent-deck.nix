{ lib, pkgs, ... }:
pkgs.buildGoModule rec {
  pname = "agent-deck";
  version = "1.7.41";

  src = pkgs.fetchFromGitHub {
    owner = "asheshgoplani";
    repo = "agent-deck";
    rev = "v${version}";
    hash = "sha256-FLN+GQQ05eB4AN15/mc1mlasT2gIIAVi/CWYJwDG+mA=";
  };

  vendorHash = "sha256-aH32Up3redCpeyjZkjcjiVN0tfYpF+GFB2WVAGm3J2I=";

  subPackages = [ "cmd/agent-deck" ];

  env.CGO_ENABLED = 0;

  # Upstream tests require git in PATH which isn't available in the Nix sandbox
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  meta = {
    description = "Terminal session manager for AI coding agents";
    homepage = "https://github.com/asheshgoplani/agent-deck";
    license = lib.licenses.mit;
    mainProgram = "agent-deck";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
