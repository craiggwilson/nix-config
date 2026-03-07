{
  config.substrate.modules.desktop.custom.nautilus = {
    tags = [ "desktop:custom" ];

    homeManager =
      { config, lib, pkgs, ... }:
      {
        hdwlinux.apps.fileManager = {
          package = pkgs.nautilus;
          desktopName = "nautilus.desktop";
        };

        home.packages = [
          pkgs.nautilus
          pkgs.nautilus-python
          pkgs.nautilus-open-any-terminal
          pkgs.sushi
        ];

        dconf.settings = lib.optionalAttrs (builtins.hasAttr "terminal" config.hdwlinux.apps) {
          "com/github/stunkymonkey/nautilus-open-any-terminal" = {
            terminal =
              let
                app = config.hdwlinux.apps.terminal;
                prog = if app.program != null then app.program else app.package.meta.mainProgram or (lib.getName app.package);
              in
              "${app.package}/bin/${prog}";
            new-tab = true;
            flatpak = "system";
            keybindings = "<Ctrl><Alt>t";
          };
        };
      };
  };
}

