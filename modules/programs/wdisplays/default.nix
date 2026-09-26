{
  config.substrate.modules.programs.wdisplays = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.wdisplays ];
      };
  };
}

