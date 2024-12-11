{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland;
  rgb = color: "rgb(${color})";
  rgba = color: alpha: "rgba(${color}${alpha})";

  criteriaFn = m: if m.description != null then "desc:${m.description}" else m.port;
  monitorFn =
    m:
    "${criteriaFn m}, ${toString m.width}x${toString m.height}, ${toString m.x}x${toString m.y}, ${toString m.scale}";
in
{
  options.hdwlinux.desktopManagers.hyprland = {
    enable = config.lib.hdwlinux.mkEnableOption "hyprland" "desktop:hyprland";
    layout = lib.mkOption {
      description = "The layout manager to use.";
      type = lib.types.enum [
        "dwindle"
        "master"
        "scroller"
      ];
      default = "dwindle";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.startServices = true;

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;

      plugins =
        [
          pkgs.hyprlandPlugins.hyprfocus
          pkgs.hyprlandPlugins.hyprspace
          pkgs.hyprlandPlugins.hyprtrails
        ]
        ++ lib.optionals (cfg.layout == "scroller") [
          pkgs.hyprlandPlugins.hyprscroller
        ];

      settings = lib.mkMerge [
        (lib.mkIf config.hdwlinux.theme.enable {
          misc.background_color = rgb config.hdwlinux.theme.colors.base00;
          general = {
            "col.active_border" = rgb config.hdwlinux.theme.colors.base0E;
            "col.inactive_border" = rgb config.hdwlinux.theme.colors.base03;
          };
          decoration.shadow.color = rgba config.hdwlinux.theme.colors.base00 "99";
          group = {
            "col.border_inactive" = rgb config.hdwlinux.theme.colors.base0D;
            "col.border_active" = rgb config.hdwlinux.theme.colors.base06;
            "col.border_locked_active" = rgb config.hdwlinux.theme.colors.base06;
          };
          plugins = {
            hyprtrails = {
              color = rgba config.hdwlinux.theme.colors.base09 "99";
            };
          };
        })
        {
          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          cursor = {
            no_hardware_cursors = true;
          };

          monitor = (builtins.map monitorFn config.hdwlinux.hardware.monitors) ++ [
            ", preferred, auto, auto"
          ];

          workspace =
            (map (m: "${m.workspace}, monitor:${criteriaFn m}, default:true, persistent:true") (
              builtins.filter (m: m.workspace != null) config.hdwlinux.hardware.monitors
            ))
            ++ [
              "special:dropdown,gapsin:5,gapsout:30,on-created-empty:foot,border:0,rounding:false,persistent:false"
            ];

          general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
            layout = cfg.layout;
          };

          decoration = {
            rounding = 10;
            blur = {
              size = 7;
              passes = 2;
              ignore_opacity = true;
              special = true;
            };

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
            };

            dim_special = 0.2;
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

          windowrulev2 = [
            "opacity .95 .85,title:^(.*Code.*)$"
            "opacity .95 .85,class:^(firefox)$"
            "opacity .95 .85,class:^(jetbrains-goland)$"
            "opacity .95 .85,class:^(Logseq)$"
            "opacity .95 .85,class:^(Slack)$"
            "float,title:^(Quick Access — 1Password)$"
            "dimaround,title:^(Quick Access — 1Password)$, floating"
            "center,title:^(Quick Access — 1Password)$"
            "stayfocused,title:^(Quick Access — 1Password)$"
            "workspace special:dropdown,class:^(foot)$"
          ];

          plugins = {

            hyprfocus = {
              enabled = "yes";
              animate_floating = "yes";
              animate_workspacechange = "yes";
              focus_animation = "shrink";
              # Beziers for focus animations
              bezier = [
                "bezIn, 0.5,0.0,1.0,0.5"
                "bezOut, 0.0,0.5,0.5,1.0"
                "overshot, 0.05, 0.9, 0.1, 1.05"
                "smoothOut, 0.36, 0, 0.66, -0.56"
                "smoothIn, 0.25, 1, 0.5, 1"
                "realsmooth, 0.28,0.29,.69,1.08"
              ];
              # Flash settings
              flash = {
                flash_opacity = 0.95;
                in_bezier = "realsmooth";
                in_speed = 0.5;
                out_bezier = "realsmooth";
                out_speed = 3;
              };
              # Shrink settings
              shrink = {
                shrink_percentage = 0.95;
                in_bezier = "realsmooth";
                in_speed = 1;
                out_bezier = "realsmooth";
                out_speed = 2;
              };
            };

            scroller = {
              column_default_width = "seveneighths";
            };

          };
        }
      ];

      extraConfig = ''
        bind=SUPER, A, exec, pkill rofi || rofi -show hyprland-keybinds
        bind=SUPER, B, exec, firefox                                                  # Launch Firefox
        bind=SUPER, E, exec, nautilus                                                 # Launch the file explorer
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
        bind=SUPER, T, exec, foot                                                     # Launch the terminal
        bind=SUPER SHIFT, T, movetoworkspace, special:dropdown                        # Move the active window to the dropdown workspace
        bind=SUPER, X, exec, pkill rofi || rofi -show power-menu                      # Show the power menu
        bind=SUPER, SPACE, exec, pkill rofi || rofi -show drun -show-icons            # Show the application launcher
        bind=SUPER, TAB, exec, pkill rofi || rofi -show window                        # Show the window switcher
        bind=SUPER, GRAVE, togglespecialworkspace, dropdown                           # Toggle the dropdown workspace
        bind=SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy  # Show the clipboard history
        bind=SUPER, ESCAPE, exec, foot btop                                           # Launch the task manager

        bind=SUPER CTRL, left, workspace, -1
        bind=SUPER CTRL, right, workspace, +1
        bind=SUPER, left, movefocus, left
        bind=SUPER, right, movefocus, right
        bind=SUPER, 1, workspace, 1
        bind=SUPER, 2, workspace, 2
        bind=SUPER, 3, workspace, 3
        bind=SUPER, 4, workspace, 4
        bind=SUPER, 5, workspace, 5
        bind=SUPER, 6, workspace, 6
        bind=SUPER, 7, workspace, 7
        bind=SUPER, 8, workspace, 8
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

        bind=SUPER SHIFT CTRL, left, resizeactive, -100 0
        bind=SUPER SHIFT CTRL, right, resizeactive, 100 0

        bind=, xf86audiomute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        binde=, xf86audioraisevolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1
        binde=, xf86audiolowervolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        binde=, xf86monbrightnessup, exec, brightnessctl set 10%+
        binde=, xf86monbrightnessdown, exec, brightnessctl set 10%-

        bindm=SUPER, mouse:272, movewindow
        bindm=SUPER, mouse:273, resizewindow
        bindm = SUPER, ALT_L, movewindow
        bindm = SUPER, Control_L, resizewindow

        bindl=,switch:off:Lid Switch,exec,hyprctl keyword monitor "${monitorFn (builtins.head config.hdwlinux.hardware.monitors)}"
        bindl=,switch:on:Lid Switch,exec,hyprctl keyword monitor "${criteriaFn (builtins.head config.hdwlinux.hardware.monitors)}, disable"

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
