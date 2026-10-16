{
  config.substrate.modules.programs.lldb = {
    provides = [ "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lldb ];
      };
  };
}
