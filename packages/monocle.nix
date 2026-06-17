{ lib, pkgs, ... }:
let
  version = "0.48.1";
in
pkgs.buildGoModule {
  name = "monocle";

  src = pkgs.fetchFromGitHub {
    owner = "josephschmitt";
    repo = "monocle";
    rev = "v${version}";
    hash = "sha256-/N9nFDwuhGXPhi/MQ7RKDLFgUoYxeyiRvsFkbRHgrIs=";
  };

  vendorHash = "sha256-oajKuhbP+DRXefoJbrOVoyE1rOdtZaPS4c3u0HUP4Kc=";

  subPackages = [ "cmd/monocle" ];

  doCheck = false;

  ldflags = [
    "-X main.version=v${version}"
  ];

  meta = {
    mainProgram = "monocle";
    description = "Review your AI agent's code as it writes it";
    homepage = "https://github.com/josephschmitt/monocle";
  };
}
