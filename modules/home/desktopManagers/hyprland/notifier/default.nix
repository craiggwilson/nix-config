{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.notifier;
in
{
  options.hdwlinux.desktopManagers.hyprland.notifier = {
    enable = lib.hdwlinux.mkEnableOption "notifier" config.hdwlinux.desktopManagers.hyprland.mako.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.libnotify
      (pkgs.writeShellApplication {
        name = "notifier-dismiss-all";
        runtimeInputs = [
          config.services.mako.package
        ];
        text = builtins.readFile ./notifier-dismiss-all.sh;
      })
      (pkgs.writeShellApplication {
        name = "notifier-send";
        runtimeInputs = [
          pkgs.libnotify
        ];
        text = builtins.readFile ./notifier-send.sh;
      })
      (pkgs.writeShellApplication {
        name = "notifier-toggle-do-not-disturb";
        runtimeInputs = [
          config.services.mako.package
        ];
        text = builtins.readFile ./notifier-toggle-do-not-disturb.sh;
      })
      (pkgs.writeShellApplication {
        name = "notifier-watch";
        runtimeInputs = [
          config.services.mako.package
          pkgs.jq
          pkgs.ripgrep
        ];
        text = builtins.readFile ./notifier-watch.sh;
      })
    ];
  };
}
