let
  root = "/home/craig/Projects/github.com/10gen/mms-automation/go_planner";
in
{
  substrate.devenv.shells.automation =
    { pkgs, ... }:
    {
      # A work shell: the go toolchain is only useful inside the checkout, so
      # enterShell checks for it. Under an impure evaluation the root follows you
      # into the checkout you opened the shell from; under a pure one it falls
      # back to $HOME, which exists and costs nothing -- devenv creates
      # `<root>/.devenv` eagerly, so pointing it at an absent checkout would
      # build the tree.
      devenv.root =
        let
          pwd = builtins.getEnv "PWD";
        in
        if pwd != "" then pwd else "/home/craig";
      packages = with pkgs; [
        gnumake
        go
        golangci-lint
        gopls
        gotools
        go-tools
        cmake
      ];
      env = {
        CM_ROOT = root;
        GOPATH = root;
      };
      enterShell = ''
        if [ ! -d "$DEVENV_ROOT" ]; then
          echo "mms-automation is not checked out at $DEVENV_ROOT" >&2
        fi
      '';
    };
}
