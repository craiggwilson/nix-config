{
  config.substrate.modules.programs.gnome-firmware = {
    provides = [ "programs:gnome-firmware" "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gnome-firmware ];
      };
  };
}
