{
  config.substrate.modules.programs.lldb = {
    provides = [
      "programs:lldb"
      "programming"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lldb ];
      };
  };
}
