{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.app;
  execKnown = app: argGroup: "uwsm app -- ${lib.hdwlinux.getAppExe app argGroup} \"$@\"";
  known = lib.mapAttrs (
    name: app:
    let
      argGroups =
        if builtins.hasAttr "default" app.argGroups then
          app.argGroups
        else
          app.argGroups // { "default" = null; };
    in
    lib.mapAttrs' (
      argGroup: _:
      lib.nameValuePair (if argGroup == "default" then "*" else argGroup) (execKnown app argGroup)
    ) argGroups
  ) config.hdwlinux.apps;
in
{
  options.hdwlinux.desktopManagers.hyprland.app = {
    enable = lib.hdwlinux.mkEnableOption "app" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
        name = "appctl";
        runtimeInputs = [
          config.programs.rofi.package
          pkgs.procps
          pkgs.uwsm
        ];
        subcommands = {
          exec = "uwsm app -- \"$@\"";
          exec-known = known;
          show-menu = ''
            pkill rofi || rofi \
              -show drun \
              -theme ${./app-menu.rasi} \
              -run-command 'appctl exec {cmd}'
          '';
          show-windows = "pkill rofi || rofi -show window";
        };
      })
    ];
  };
}
