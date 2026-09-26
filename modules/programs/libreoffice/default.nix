{
  config.substrate.modules.programs.libreoffice = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.libreoffice ];
      };
  };
}

