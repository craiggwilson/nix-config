{
  config.substrate.modules.programs.mission-center = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.mission-center ];
      };
  };
}

