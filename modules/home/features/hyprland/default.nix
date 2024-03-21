{ options, config, lib, pkgs, osConfig, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.hyprland;
  rgb = color: "rgb(${color})";
  rgba = color: alpha: "rgba(${color}${alpha})";
in
{
  options.hdwlinux.features.hyprland = with types; {
    enable = mkEnableOpt ["desktop:hyprland"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    systemd.user.startServices = true;

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;

      settings = mkMerge [
        (mkIf config.hdwlinux.theme.enable {
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

          monitor = (builtins.map (m: 
            "${m.name}, ${toString m.width}x${toString m.height}, ${toString m.x}x${toString m.y}, ${toString m.scale}"
          ) config.hdwlinux.features.monitors.monitors)
          ++ [ ", preferred, auto, auto" ];

          workspace = (map (m: 
            "${m.workspace}, monitor:${m.name}"
          ) config.hdwlinux.features.monitors.monitors) ++ [
            "special:dropdown,gapsin:5,gapsout:30,on-created-empty:kitty,border:0,rounding:false,persistent:false"
          ];

          env = [
            "XCURSOR_SIZE,24"
          ];

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

            dim_special = .2;
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
            new_is_master = true;
            special_scale_factor = 1;
          };

          gestures = {
            workspace_swipe = true;
          };

          # "device:epic-mouse-v1" = {
          #   sensitivity = -0.5;
          # };

          exec-once = [
            "swayidle -w"
            "waybar"
            "hyprpaper"
            "dunst"
            "nm-applet --indicator"
            "1password --silent"
            "wl-paste --type text --watch cliphist store"
            "wl-paste --type image --watch cliphist store"
          ];

          bind = [
            "SUPER, B, exec, firefox"
            "SUPER, E, exec, thunar"
            "SUPER, L, exec, 1password --toggle"
            "SUPER ALT, L, exec, 1password --quick-access"
            "SUPER, X, exec, rofi -show power-menu"
            "SUPER, P, exec, $colorPicker"
            "SUPER, SPACE, exec, pkill rofi || rofi -show drun -show-icons"
            "SUPER ALT , SPACE, exec, rofi -show run -show-icons"
            "SUPER, TAB, exec, rofi -show window -show-icons"
            "SUPER, T, exec, kitty"
            "SUPER, GRAVE, togglespecialworkspace, dropdown"
            "SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
            ", xf86audiomute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            "SUPER, ESCAPE, exec, kitty btop"

            # Move focus with mainMod + arrow keys
            "SUPER, left, movefocus, l"
            "SUPER, right, movefocus, r"
            "SUPER, up, movefocus, u"
            "SUPER, down, movefocus, d"

            # Switch workspaces with mainMod + [0-9]
            "SUPER CONTROL, left, workspace, -1"
            "SUPER CONTROL, right, workspace, +1"
            "SUPER, 1, workspace, 1"
            "SUPER, 2, workspace, 2"
            "SUPER, 3, workspace, 3"
            "SUPER, 4, workspace, 4"
            "SUPER, 5, workspace, 5"
            "SUPER, 6, workspace, 6"
            "SUPER, 7, workspace, 7"
            "SUPER, 8, workspace, 8"
            "SUPER, 9, workspace, 9"
            "SUPER, 0, workspace, 10"

            # Manipuate active window mainMod + SHIFT
            "SUPER SHIFT, W, killactive,"
            "SUPER SHIFT, P, pseudo,"
            "SUPER SHIFT, J, togglesplit,"
            "SUPER SHIFT, F, togglefloating,"
            "SUPER SHIFT, RETURN, fullscreen, 1"
            "SUPER SHIFT, left, movetoworkspace, -1"
            "SUPER SHIFT, right, movetoworkspace, +1"
            "SUPER SHIFT, 1, movetoworkspace, 1"
            "SUPER SHIFT, 2, movetoworkspace, 2"
            "SUPER SHIFT, 3, movetoworkspace, 3"
            "SUPER SHIFT, 4, movetoworkspace, 4"
            "SUPER SHIFT, 5, movetoworkspace, 5"
            "SUPER SHIFT, 6, movetoworkspace, 6"
            "SUPER SHIFT, 7, movetoworkspace, 7"
            "SUPER SHIFT, 8, movetoworkspace, 8"
            "SUPER SHIFT, 9, movetoworkspace, 9"
            "SUPER SHIFT, 0, movetoworkspace, 10"
            "SUPER SHIFT, T, movetoworkspace, special:dropdown"

            # Scroll through existing workspaces with mainMod + scroll
            "SUPER, mouse_down, workspace, e+1"
            "SUPER, mouse_up, workspace, e-1"
          ];

          binde = [
            ", xf86audioraisevolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1"
            ", xf86audiolowervolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ", xf86monbrightnessup, exec, brightnessctl set 10%+"
            ", xf86monbrightnessdown, exec, brightnessctl set 10%-"
          ];

          bindm = [
            # Move/resize windows with mainMod + LMB/RMB and dragging
            "SUPER, mouse:272, movewindow"
            "SUPER, mouse:273, resizewindow"
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
        }
      ];

      extraConfig = ''
        bind = , PRINT, submap, screenshot
        submap = screenshot
        bind = , a, exec, grimblast copy area
        bind = , a, submap, reset
        bind = CONTROL, a, exec, grimblast edit area
        bind = CONTROL, a, submap, reset
        bind = CONTROL SHIFT, a, exec, grimblast copysave area "~/Pictures/Screenshots/$(date +'%s_grim_area.png')"
        bind = CONTROL SHIFT, a, submap, reset

        bind = , m, exec, grimblast copy output
        bind = , m, submap, reset
        bind = CONTROL, m, exec, grimblast edit output
        bind = CONTROL, m, submap, reset
        bind = CONTROL SHIFT, m, exec, grimblast copysave output "~/Pictures/Screenshots/$(date +'%s_grim_monitor.png')"
        bind = CONTROL SHIFT, m, submap, reset

        bind = , s, exec, grimblast copy screen
        bind = , s, submap, reset
        bind = CONTROL, s, exec, grimblast edit screen
        bind = CONTROL, s, submap, reset
        bind = CONTROL SHIFT, s, exec, grimblast copysave screen "~/Pictures/Screenshots/$(date +'%s_grim_screen.png')"
        bind = CONTROL SHIFT, s, submap, reset

        bind = , w, exec, grimblast copy active
        bind = , w, submap, reset
        bind = CONTROL, w, exec, grimblast edit active
        bind = CONTROL, w, submap, reset
        bind = CONTROL SHIFT, w, exec, grimblast copysave active "~/Pictures/Screenshots/$(date +'%s_grim_window.png')"
        bind = CONTROL SHIFT, w, submap, reset

        bind = , ESCAPE, submap, reset
        submap = reset
      '';
    };
  };
}
