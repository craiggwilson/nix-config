{
  config.substrate.modules.programs.papers = {
    tags = [ "desktop" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.desktop.apps.documentViewer = lib.mkDefault {
          package = pkgs.papers;
          desktopName = "org.gnome.Papers.desktop";
        };

        home.packages = [ pkgs.papers ];
      };
  };
}
