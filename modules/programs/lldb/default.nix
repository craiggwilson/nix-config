{
  config.substrate.modules.programs.lldb = {
    provides = [ "programs:lldb" "programming" ];
    tags = [ "programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lldb ];
      };
  };
}
