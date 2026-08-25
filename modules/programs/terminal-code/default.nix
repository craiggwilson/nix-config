{
  config.substrate.modules.programs.terminal-code = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.terminal-code ];
      };
  };
}
