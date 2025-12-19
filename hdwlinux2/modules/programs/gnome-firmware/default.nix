{
  config.substrate.modules.programs.gnome-firmware = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gnome-firmware ];
      };
  };
}

