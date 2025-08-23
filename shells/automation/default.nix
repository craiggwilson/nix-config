{
  pkgs,
  ...
}:

let
  path = "/home/craig/Projects/github.com/10gen/mms-automation/go_planner";
in

pkgs.mkShell {
  buildInputs = with pkgs; [
    gnumake
    go
    golangci-lint
    gopls
    gotools
    go-tools
    cmake
  ];

  CM_ROOT = path;
  GOPATH = path;
}
