{
  config.substrate.modules.programs.manix = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.manix ];
      };
  };
}

