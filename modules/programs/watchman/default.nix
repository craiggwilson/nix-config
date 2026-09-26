{
  config.substrate.modules.programs.watchman = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.watchman ];
      };
  };
}

