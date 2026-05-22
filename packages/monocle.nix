{ lib, pkgs, ... }:
let
  version = "0.46.1";
in
pkgs.buildGoModule {
  name = "monocle";

  src = pkgs.fetchFromGitHub {
    owner = "josephschmitt";
    repo = "monocle";
    rev = "v${version}";
    hash = "sha256-2ye2Y/yrJXebGX++B8ILDhZpsm4NxZ5RRRDI/dzfOpY=";
  };

  vendorHash = "sha256-oajKuhbP+DRXefoJbrOVoyE1rOdtZaPS4c3u0HUP4Kc=";

  subPackages = [ "cmd/monocle" ];

  ldflags = [
    "-X main.version=v${version}"
  ];

  meta = {
    mainProgram = "monocle";
    description = "Review your AI agent's code as it writes it";
    homepage = "https://github.com/josephschmitt/monocle";
  };
}
