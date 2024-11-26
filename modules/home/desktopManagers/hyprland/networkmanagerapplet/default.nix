{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.networkmanagerapplet;
in
{
  options.hdwlinux.desktopManagers.hyprland.networkmanagerapplet = {
    enable = lib.hdwlinux.mkEnableOption "networkmanagerapplet" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.networkmanagerapplet ];

    systemd.user.services.networkmanagerapplet = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "Network Manager Applet";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session-pre.target" ];
      };
      Service = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
