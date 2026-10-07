{
  pkgs,
  ...
}:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    go
    golangci-lint
    gopls
    gotools
    go-tools
  ];
}
