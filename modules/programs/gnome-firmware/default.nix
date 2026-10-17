{
  config.substrate.modules.programs.gnome-firmware = {
    provides = [
      "programs:gnome-firmware"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gnome-firmware ];
      };
  };
}
