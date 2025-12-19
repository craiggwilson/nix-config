{
  config.substrate.modules.programs.go = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          go
          golangci-lint
          gopls
          gotools
          go-tools
        ];
      };
  };
}

