{
  config.substrate.modules.desktop.custom.nautilus = {
    tags = [ "desktop:custom" ];

    homeManager =
      { config, lib, pkgs, ... }:
      {
        hdwlinux.app.fileManager = lib.mkDefault {
          package = pkgs.nautilus;
          desktopName = "nautilus.desktop";
        };

        home.packages = [
          pkgs.nautilus
          pkgs.nautilus-python
          pkgs.nautilus-open-any-terminal
          pkgs.sushi
        ];

        dconf.settings = lib.optionalAttrs (config.hdwlinux.app.terminal != null) {
          "com/github/stunkymonkey/nautilus-open-any-terminal" = {
            terminal = lib.getExe config.hdwlinux.app.terminal.package;
            new-tab = true;
            flatpak = "system";
            keybindings = "<Ctrl><Alt>t";
          };
        };
      };
  };
}

