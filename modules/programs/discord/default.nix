{
  config.substrate.modules.programs.discord = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.discord ];
      };
  };
}

