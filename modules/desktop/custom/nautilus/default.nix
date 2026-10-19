{
  config.substrate.modules.desktop.custom.nautilus = {
    tags = [ "desktop:custom" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        hdwlinux.desktop.apps.fileManager = lib.mkDefault {
          package = pkgs.nautilus;
          desktopName = "nautilus.desktop";
        };

        home.packages = [
          pkgs.nautilus
          pkgs.nautilus-python
          pkgs.nautilus-open-any-terminal
          pkgs.sushi
        ];

        dconf.settings = lib.optionalAttrs (config.hdwlinux.desktop.apps.terminal != null) {
          "com/github/stunkymonkey/nautilus-open-any-terminal" = {
            terminal = lib.getExe config.hdwlinux.desktop.apps.terminal.package;
            new-tab = true;
            flatpak = "system";
            keybindings = "<Ctrl><Alt>t";
          };
        };
      };
  };
}
