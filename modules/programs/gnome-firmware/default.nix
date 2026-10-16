{
  config.substrate.modules.programs.gnome-firmware = {
    provides = [ "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gnome-firmware ];
      };
  };
}
