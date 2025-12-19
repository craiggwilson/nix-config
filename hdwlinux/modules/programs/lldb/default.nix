{
  config.substrate.modules.programs.lldb = {
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lldb ];
      };
  };
}

