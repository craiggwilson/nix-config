{
  config.substrate.modules.programs.go = {
    tags = [ "profile:programming" ];

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
