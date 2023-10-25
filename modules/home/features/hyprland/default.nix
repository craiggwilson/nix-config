{ options, config, lib, pkgs, osConfig, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.hyprland;
in
{
  options.hdwlinux.features.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to enable hyprland.";
    settings = mkOpt attrs { } (mdDoc "Options passed directly to home-manager's `wayland.windowManager.hyprland.settings`.");
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      enableNvidiaPatches = builtins.elem "nvidia" osConfig.services.xserver.videoDrivers;
      systemd.enable = true;

      settings = {
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        monitor = (builtins.map (m: 
          "${m.name}, ${toString m.width}x${toString m.height}, ${toString m.x}x${toString m.y}, ${toString m.scale}"
        ) config.hdwlinux.features.monitors.monitors)
        ++ [ ", preferred, auto, auto" ];

        workspace = map (m: 
          "${m.workspace}, monitor:${m.name}"
        ) config.hdwlinux.features.monitors.monitors;

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
          };

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

          touchpad = {
            natural_scroll = true;
          };

          sensitivity = 0;
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

        exec-once = [
          #"swayidle -w timeout 300 'swaylock' timeout 330 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'"
          "swayidle -w timeout 60 'if pgrep -x swaylock; then hyprctl dispatch dpms off; fi' resume 'hyprctl dispatch dpms on'"
          "waybar"
          "hyprpaper"
          "nm-applet --indicator"
          "dunst"
          "1password --silent"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
        ];

        "$mainMod" = "SUPER";
        "$browser" = "firefox";
        "$colorPicker" = "hyprpicker -r -n -a";
        "$fileManager" = "thunar";
        "$launcher" = "rofi -show drun -show-icons";
        "$launcherAlt" = "rofi -show run -show-icons";
        "$password" = "1password --toggle";
        "$passwordQuick" = "1password --quick-access";
        "$logoutMenu" = "wlogout -b 2";
        "$switchWindows" = "rofi -show window -show-icons";
        "$term" = "kitty";

        bind = [
          "$mainMod, B, exec, $browser"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, L, exec, $password"
          "$mainMod CONTROL, L, exec, $passwordQuick"
          "$mainMod, X, exec, $logoutMenu"
          "$mainMod, P, exec, $colorPicker"
          "$mainMod, R, exec, $launcherAlt"
          "$mainMod, SPACE, exec, $launcher"
          "$mainMod, T, exec, $term"
          "$mainMod, TAB, exec, $switchWindows"
          "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
          ", xf86audiomute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

          "$mainMod CONTROL, ESCAPE, exec, $term btop"

          # Move focus with mainMod + arrow keys
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "$mainMod CONTROL, left, workspace, -1"
          "$mainMod CONTROL, right, workspace, +1"
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
          "$mainMod SHIFT, W, killactive,"
          "$mainMod SHIFT, P, pseudo,"
          "$mainMod SHIFT, J, togglesplit,"
          "$mainMod SHIFT, F, togglefloating,"
          "$mainMod SHIFT, RETURN, fullscreen, 1"
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

        binde = [
          ", xf86audioraisevolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1"
          ", xf86audiolowervolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", xf86monbrightnessup, exec, brightnessctl set 10%+"
          ", xf86monbrightnessdown, exec, brightnessctl set 10%-"
        ];

        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        windowrulev2 = [
          "opacity .95 .85,title:^(.*Code.*)$"
          "opacity .95 .85,class:^(firefox)$"
          "opacity .95 .85,class:^(jetbrains-goland)$"
          "opacity .95 .85,class:^(kitty)$"
          "opacity .95 .85,class:^(Logseq)$"
          "opacity .95 .85,class:^(Slack)$"
          "float, title:^(Quick Access — 1Password)$"
          "dimaround, title:^(Quick Access — 1Password)$, floating"
          "center, title:^(Quick Access — 1Password)$"
          "stayfocused,title:^(Quick Access — 1Password)$"
        ];
      } // cfg.settings;

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
