{
  config.substrate.modules.programs.go = {
    provides = [ "programming" ];
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
