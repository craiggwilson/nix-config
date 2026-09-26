{
  config.substrate.modules.programs.gamescope = {
    tags = [ "gui" "gaming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.gamescope ];
      };
  };
}

