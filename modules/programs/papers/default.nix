{
  config.substrate.modules.programs.papers = {
    tags = [ "gui" ];

    perUser =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.documentViewer = lib.mkDefault {
          package = pkgs.papers;
          desktopName = "org.gnome.Papers.desktop";
        };

        packages = [ pkgs.papers ];
      };
  };
}
