{
  config.substrate.modules.programs.gnome-firmware = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.gnome-firmware ];
      };
  };
}
