{
  config.substrate.modules.programs.cava = {
    tags = [ "audio" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.cava ];
      };
  };
}

