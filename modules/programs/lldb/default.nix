{
  config.substrate.modules.programs.lldb = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.lldb ];
      };
  };
}

