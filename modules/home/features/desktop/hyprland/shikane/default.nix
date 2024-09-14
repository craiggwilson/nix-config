{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.shikane;
  profiles = config.hdwlinux.monitors.profiles;
  monitors = config.hdwlinux.monitors.monitors;
in
{
  options.hdwlinux.features.desktop.hyprland.shikane = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf (cfg.enable && (builtins.length profiles > 0)) {

    home.packages = [ pkgs.shikane ];

    services.kanshi = {
      enable = true;
      systemdTarget = "hyprland-session.target";

      profiles = builtins.listToAttrs (
        builtins.map (profile: {
          name = profile;
          value = {
            outputs = builtins.map (m: {
              criteria = if m.description != null then m.description else m.port;
              position = "${builtins.toString m.x},${builtins.toString m.y}";
              mode = "${builtins.toString m.width}x${builtins.toString m.height}";
              scale = m.scale;
              status = if builtins.getAttr profile m.profiles then "enable" else "disable";
            }) (builtins.filter (m: builtins.hasAttr profile m.profiles) monitors);
          };
        }) profiles
      );
    };
  };
}
