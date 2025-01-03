{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.screenshotter;
in
{
  options.hdwlinux.desktopManagers.hyprland.screenshotter = {
    enable = lib.hdwlinux.mkEnableOption "screenshotter" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "screenshotter-menu";
        runtimeInputs = [
          config.programs.rofi.package
          pkgs.hyprshot
        ];
        text = builtins.replaceStrings [ "screenshotter-menu.rasi" ] [ "${./screenshotter-menu.rasi}" ] (
          builtins.readFile ./screenshotter-menu.sh
        );
      })
    ];
  };
}
