{
  config.substrate.modules.programs.lldb = {
    tags = [ "profile:programming" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lldb ];
      };
  };
}
