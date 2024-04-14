{ lib, inputs, pkgs, stdenv,...}:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    stable.go_1_20
    golangci-lint
    gopls
    gotools
    go-tools
  ];
}
