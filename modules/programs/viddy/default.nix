{
  config.substrate.modules.programs.viddy = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.viddy ];
      };
  };
}

