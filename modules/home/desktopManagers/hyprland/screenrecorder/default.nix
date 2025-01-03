{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.screenrecorder;
in
{
  options.hdwlinux.desktopManagers.hyprland.screenrecorder = {
    enable = lib.hdwlinux.mkEnableOption "screenrecorder" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "screenrecorder-is-recording";
        runtimeInputs = [ pkgs.procps ];
        text = builtins.readFile ./screenrecorder-is-recording.sh;
      })
      (pkgs.writeShellApplication {
        name = "screenrecorder-menu";
        runtimeInputs = [
          config.programs.rofi.package
          pkgs.ffmpeg
          pkgs.libnotify
          pkgs.procps
          pkgs.slurp
          pkgs.wl-screenrec
        ];
        text = builtins.replaceStrings [ "screenrecorder-menu.rasi" ] [ "${./screenrecorder-menu.rasi}" ] (
          builtins.readFile ./screenrecorder-menu.sh
        );
      })
      (pkgs.writeShellApplication {
        name = "screenrecorder-stop";
        runtimeInputs = [ pkgs.procps ];
        text = builtins.readFile ./screenrecorder-stop.sh;
      })
      (pkgs.writeShellApplication {
        name = "screenrecorder-watch";
        text = builtins.readFile ./screenrecorder-watch.sh;
      })
    ];
  };
}
