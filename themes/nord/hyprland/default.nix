{ lib, pkgs, config, ... }:
with lib;
{
  hdwlinux.packages.hyprland.settings = {
    misc = {
      disable_hyprland_logo = true;
    };

    env = [
      "XCURSOR_SIZE,24"
    ];

    general = {
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
      "col.active_border" = "rgba(88c0d0ee) rgba(8fbcbbee) 45deg";
      "col.inactive_border" = "rgba(5e81acaa)";
    };

    decoration = {
      rounding = 10;
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
      };

      drop_shadow = true;
      shadow_range = 4;
      shadow_render_power = 3;
      "col.shadow" = "rgba(1d2129aa)";
    };

    animations = {
      enabled = true;
      bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

      animation = [
        "windows, 1, 7, myBezier"
        "windowsOut, 1, 7, default, popin 80%"
        "border, 1, 10, default"
        "borderangle, 1, 8, default"
        "fade, 1, 7, default"
        "workspaces, 1, 6, default"
      ];
    };
  };
}
