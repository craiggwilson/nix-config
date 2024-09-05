{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.desktop.hyprland.hyprland;
  rgb = color: "rgb(${color})";
  rgba = color: alpha: "rgba(${color}${alpha})";

  criteria = m: if m.description != null then "desc:${m.description}" else m.port;
in
{
  options.hdwlinux.features.desktop.hyprland.hyprland = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    systemd.user.startServices = true;

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;

      plugins = [
        pkgs.hyprlandPlugins.hypr-dynamic-cursors
        pkgs.hyprlandPlugins.hyprspace
        pkgs.hyprlandPlugins.hyprtrails
      ];

      settings = lib.mkMerge [
        (lib.mkIf config.hdwlinux.theme.enable {
          misc.background_color = rgb config.hdwlinux.theme.colors.base00;
          general = {
            "col.active_border" = rgb config.hdwlinux.theme.colors.base0E;
            "col.inactive_border" = rgb config.hdwlinux.theme.colors.base03;
          };
          decoration."col.shadow" = rgba config.hdwlinux.theme.colors.base00 "99";
          group = {
            "col.border_inactive" = rgb config.hdwlinux.theme.colors.base0D;
            "col.border_active" = rgb config.hdwlinux.theme.colors.base06;
            "col.border_locked_active" = rgb config.hdwlinux.theme.colors.base06;
          };
        })
        {
          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          monitor =
            (builtins.map (
              m:
              "${criteria m}, ${toString m.width}x${toString m.height}, ${toString m.x}x${toString m.y}, ${toString m.scale}"
            ) config.hdwlinux.monitors)
            ++ [ ", preferred, auto, auto" ];

          workspace =
            (map (
              m: "${m.workspace}, monitor:${criteria m}, default:true, persistent:true"
            ) config.hdwlinux.monitors)
            ++ [
              "special:dropdown,gapsin:5,gapsout:30,on-created-empty:kitty,border:0,rounding:false,persistent:false"
            ];

          env = [ "XCURSOR_SIZE,24" ];

          general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
          };

          decoration = {
            rounding = 10;
            blur = {
              size = 7;
              passes = 2;
              ignore_opacity = true;
              special = true;
            };

            dim_special = 0.2;
            drop_shadow = true;
            shadow_range = 4;
            shadow_render_power = 3;
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

          input = {
            kb_layout = "us";
            kb_variant = "";
            kb_model = "";
            kb_options = "";
            kb_rules = "";
            follow_mouse = 2;
            mouse_refocus = false;

            touchpad = {
              natural_scroll = true;
            };

            sensitivity = 0;
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
            special_scale_factor = 1;
          };

          master = {
            new_status = "master";
            special_scale_factor = 1;
          };

          gestures = {
            workspace_swipe = true;
          };

          exec-once = [
            "ags"
            "hypridle"
            "dunst"
            "nm-applet --indicator"
            "1password --silent"
            "wl-paste --type text --watch cliphist store"
            "wl-paste --type image --watch cliphist store"
          ];

          windowrulev2 = [
            "opacity .95 .85,title:^(.*Code.*)$"
            "opacity .95 .85,class:^(firefox)$"
            "opacity .95 .85,class:^(jetbrains-goland)$"
            "opacity .95 .85,class:^(kitty)$"
            "opacity .95 .85,class:^(Logseq)$"
            "opacity .95 .85,class:^(Slack)$"
            "float,title:^(Quick Access — 1Password)$"
            "dimaround,title:^(Quick Access — 1Password)$, floating"
            "center,title:^(Quick Access — 1Password)$"
            "stayfocused,title:^(Quick Access — 1Password)$"
            "workspace special:dropdown,class:^(kitty)$"
          ];

          plugins = {
            dynamic-cursors = {
              enabled = true;
              mode = "tilt";

              shake = {
                enabled = true;
              };
            };
          };
        }
      ];

      extraConfig = ''
        bind=SUPER, A, exec, pkill rofi || rofi -show hyprland-keybinds
        bind=SUPER, B, exec, firefox                                                  # Launch Firefox
        bind=SUPER, E, exec, thunar                                                   # Launch the file explorer
        bind=SUPER, G, togglefloating,                                                # Toggle floating for the active window
        bind=SUPER, L, exec, 1password --toggle                                       # Launch 1Password
        bind=SUPER SHIFT,L, exec, 1password --lock                                    # Lock 1Password
        bind=SUPER ALT, L, exec, 1password --quick-access                             # Launch 1Password Quick Access 
        bind=SUPER, M, fullscreen, 1                                                  # Maximize active window
        bind=SUPER SHIFT, M, fullscreen, 0                                            # Toggle fullscreen for the active window
        bind=SUPER, O, togglesplit,                                                   # Change the orientation for the active window
        bind=SUPER, P, exec, hyprpicker                                               # Choose a color from the screen
        bind=SUPER, Q, killactive                                                     # Kill the active window
        bind=SUPER, S, togglegroup,                                                   # Toggle stacking for the active window
        bind=SUPER, T, exec, kitty                                                    # Launch the terminal
        bind=SUPER SHIFT, T, movetoworkspace, special:dropdown                        # Move the active window to the dropdown workspace
        bind=SUPER, X, exec, pkill rofi || rofi -show power-menu                      # Show the power menu
        bind=SUPER, SPACE, exec, pkill rofi || rofi -show drun -show-icons            # Show the application launcher
        bind=SUPER, TAB, exec, pkill rofi || rofi -show window                        # Show the window switcher
        bind=SUPER, GRAVE, togglespecialworkspace, dropdown                           # Toggle the dropdown workspace
        bind=SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy  # Show the clipboard history
        bind=SUPER, ESCAPE, exec, kitty btop                                          # Launch the task manager

        bind=SUPER, left, workspace, -1
        bind=SUPER, right, workspace, +1
        bind=SUPER, 1, workspace, 1
        bind=SUPER, 2, workspace, 2
        bind=SUPER, 3, workspace, 3
        bind=SUPER, 4, workspace, 4
        bind=SUPER, 5, workspace, 5
        bind=SUPER, 6, workspace, 6
        bind=SUPER, 7, workspace, 7
        bind=SUPER, 8, workspace, 8w
        bind=SUPER, 9, workspace, 9
        bind=SUPER, 0, workspace, 10

        bind=SUPER SHIFT, left, movetoworkspace, -1
        bind=SUPER SHIFT, right, movetoworkspace, +1
        bind=SUPER SHIFT, 1, movetoworkspace, 1
        bind=SUPER SHIFT, 2, movetoworkspace, 2
        bind=SUPER SHIFT, 3, movetoworkspace, 3
        bind=SUPER SHIFT, 4, movetoworkspace, 4
        bind=SUPER SHIFT, 5, movetoworkspace, 5
        bind=SUPER SHIFT, 6, movetoworkspace, 6
        bind=SUPER SHIFT, 7, movetoworkspace, 7
        bind=SUPER SHIFT, 8, movetoworkspace, 8
        bind=SUPER SHIFT, 9, movetoworkspace, 9
        bind=SUPER SHIFT, 0, movetoworkspace, 10

        bind=, xf86audiomute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        binde=, xf86audioraisevolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1
        binde=, xf86audiolowervolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        binde=, xf86monbrightnessup, exec, brightnessctl set 10%+
        binde=, xf86monbrightnessdown, exec, brightnessctl set 10%-

        bindm=SUPER, mouse:272, movewindow
        bindm=SUPER, mouse:273, resizewindow

        bind=, PRINT, submap, screenshot
        submap=screenshot
        bind=, a, exec, grimblast copy area
        bind=, a, submap, reset
        bind=CONTROL, a, exec, grimblast edit area
        bind=CONTROL, a, submap, reset
        bind=CONTROL SHIFT, a, exec, grimblast copysave area "~/Pictures/Screenshots/$(date +'%s_grim_area.png')"
        bind=CONTROL SHIFT, a, submap, reset

        bind=, m, exec, grimblast copy output
        bind=, m, submap, reset
        bind=CONTROL, m, exec, grimblast edit output
        bind=CONTROL, m, submap, reset
        bind=CONTROL SHIFT, m, exec, grimblast copysave output "~/Pictures/Screenshots/$(date +'%s_grim_monitor.png')"
        bind=CONTROL SHIFT, m, submap, reset

        bind=, s, exec, grimblast copy screen
        bind=, s, submap, reset
        bind=CONTROL, s, exec, grimblast edit screen
        bind=CONTROL, s, submap, reset
        bind=CONTROL SHIFT, s, exec, grimblast copysave screen "~/Pictures/Screenshots/$(date +'%s_grim_screen.png')"
        bind=CONTROL SHIFT, s, submap, reset

        bind=, w, exec, grimblast copy active
        bind=, w, submap, reset
        bind=CONTROL, w, exec, grimblast edit active
        bind=CONTROL, w, submap, reset
        bind=CONTROL SHIFT, w, exec, grimblast copysave active "~/Pictures/Screenshots/$(date +'%s_grim_window.png')"
        bind=CONTROL SHIFT, w, submap, reset

        bind=, ESCAPE, submap, reset
        submap=reset
      '';
    };
  };
}
