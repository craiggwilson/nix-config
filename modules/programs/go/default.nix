{
  config.substrate.modules.programs.go = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = with pkgs; [
          go
          golangci-lint
          gopls
          go-tools
        ];
      };
  };
}

