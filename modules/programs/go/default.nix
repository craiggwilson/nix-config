{
  config.substrate.modules.programs.go = {
    provides = [ "programs:go" "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          go
          golangci-lint
          gopls
          go-tools
        ];
      };
  };
}
