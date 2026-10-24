{
  substrate.publish.devShells.automation =
    {
      pkgs,
      ...
    }:

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

      # Workspace lives under ~/Projects, anchored at $HOME so the shape holds on
      # every machine; shellHook expands it since env values are evaluated literally.
      shellHook = ''
        export CM_ROOT="$HOME/Projects/github.com/10gen/mms-automation/go_planner"
        export GOPATH="$CM_ROOT"
      '';
    };
}
