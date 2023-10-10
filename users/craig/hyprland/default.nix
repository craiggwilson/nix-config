{ lib, pkgs, config, ... }:
with lib;
{
  hdwlinux.packages.hyprland.settings = {
    misc = {
      disable_hyprland_logo = true;
    };

    monitor = [
      "DP-5, 2560x1440, 0x0, 1"
      "DP-6, 2560x1440, 2560x0, 1"
      "eDP-1, highres, 0x1440, 1"
      ", preferred, auto, auto"
    ];

    workspace = [
      "1, monitor:eDP-1"
      "2, monitor:DP-5"
      "3, monitor:DP-6"
    ];

    env = [
      "XCURSOR_SIZE,24"
    ];

    input = {
      kb_layout = "us";
      kb_variant = "";
      kb_model = "";
      kb_options = "";
      kb_rules = "";
      follow_mouse = 1;

      touchpad = {
        natural_scroll = true;
      };

      sensitivity = 0;
    };

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

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    master = {
      new_is_master = true;
    };

    gestures = {
      workspace_swipe = true;
    };

    "device:epic-mouse-v1" = {
      sensitivity = -0.5;
    };
 
    "$mainMod" = "SUPER";
    "$browser" = "firefox";
    "$colorPicker" = "hyprpicker -r -n -a";
    "$fileManager" = "nautilus";
    "$infoBar" = "waybar";
    "$launcher" = "rofi -show drun -show-icons";
    "$launcherAlt" = "rofi -show run -show-icons";
    "$locker" = "swaylock";
    "$switchWindows" = "rofi -show window -show-icons";
    "$term" = "kitty";

    "$onIdle" = "swayidle -w timeout 300 'swaylock' timeout 330 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'";
    "$onIdleLocked" = "swayidle -w timeout 60 'if pgrep -x swaylock; then hyprctl dispatch dpms off; fi' resume 'hyprctl dispatch dpms on'";

    exec-once = [
      "hyprpaper"
      #"$onIdle"
      "$onIdleLocked"
      "$infoBar"
      "nm-applet --indicator"
      "dunst"
      "1password --silent"
    ];

    bind = [
      "$mainMod, T, exec, $term"
      "$mainMod, M, exit,"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, V, togglefloating,"
      "$mainMod, SPACE, exec, $launcher"
      "$mainMod CONTROL, SPACE, exec, $launcherAlt"
      "$mainMod, L, exec, $locker"
      "$mainMod CONTROL, ESCAPE, exec, $term btop"
      "$mainMod, B, exec, $browser"
      "$mainMod, P, exec, $colorPicker"
      "$mainMod, TAB, exec, $switchWindows"

      # Move focus with mainMod + arrow keys
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Switch workspaces with mainMod + [0-9]
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"

      # Manipuate active window mainMod + SHIFT
      "$mainMod SHIFT, q, killactive,"
      "$mainMod SHIFT, P, pseudo,"
      "$mainMod SHIFT, J, togglesplit,"
      "$mainMod SHIFT, left, movetoworkspace, -1"
      "$mainMod SHIFT, right, movetoworkspace, +1"
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"

      # Scroll through existing workspaces with mainMod + scroll
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
    ];

    bindm = [
      # Move/resize windows with mainMod + LMB/RMB and dragging
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

  };
}
