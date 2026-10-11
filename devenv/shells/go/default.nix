{
  substrate.devenv.shells.go =
    { pkgs, ... }:
    {
      devenv.root = "/home/craig";
      packages = with pkgs; [
        go
        golangci-lint
        gopls
        gotools
        go-tools
      ];
    };
}
