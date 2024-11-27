{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.nautilus;
in
{
  options.hdwlinux.desktopManagers.hyprland.nautilus = {
    enable = lib.mkOption {
      description = "Whether to enable nautilus.";
      type = lib.types.bool;
      default = config.hdwlinux.desktopManagers.hyprland.enable;
    };
  };

  config = lib.mkIf cfg.enable {
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

    #services.tumbler.enable = true; # Thumbnail support for images

    dconf.settings = lib.optionalAttrs (builtins.hasAttr "terminal" config.hdwlinux.apps) {
      "com/github/stunkymonkey/nautilus-open-any-terminal" = {
        terminal = lib.hdwlinux.getAppExe' config.hdwlinux.apps.terminal;
        new-tab = true;
        flatpak = "system";
        keybindings = "<Ctrl><Alt>t";
      };
    };
  };
}
