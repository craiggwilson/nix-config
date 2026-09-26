{
  config.substrate.modules.programs.vlc = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.vlc ];
      };
  };
}

