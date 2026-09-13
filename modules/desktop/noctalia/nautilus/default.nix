{
  config.substrate.modules.desktop.noctalia.nautilus = {
    tags = [ "desktop:noctalia" ];

    # Plain nautilus so app-fileManager (and the Mod+E bind) work without
    # depending on desktop/custom/nautilus.
    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.fileManager = lib.mkDefault {
          package = pkgs.nautilus;
          desktopName = "nautilus.desktop";
        };

        home.packages = [ pkgs.nautilus ];
      };
  };
}
