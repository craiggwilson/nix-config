{
  config.substrate.modules.programs.gnome-firmware = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.gnome-firmware ];
      };
  };
}

