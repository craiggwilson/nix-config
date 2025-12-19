let
  # Shared configuration values for both NixOS and home-manager
  xwaylandEnabled = true;
in
{
  config.substrate.modules.desktop.custom.hyprland = {
    tags = [
      "gui"
      "desktop:custom:hyprland"
    ];

    nixos =
      { pkgs, ... }:
      {
        programs.hyprland = {
          enable = true;
          xwayland.enable = xwaylandEnabled;
          withUWSM = true;
        };

        environment.sessionVariables = {
          GSK_RENDERER = "gl";
        };

        xdg.portal = {
          enable = true;
          config.Hyprland = {
            default = [
              "hyprland"
              "gtk"
              "wlr"
            ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
          extraPortals = [
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-wlr
          ];
          xdgOpenUsePortal = true;
        };
      };

    homeManager =
      {
        lib,
        config,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors;
        rgb = color: "rgb(${color})";
        rgba = color: alpha: "rgba(${color}${alpha})";

        laptopMonitor = config.hdwlinux.hardware.monitors.laptop or null;

        # Helper to describe monitor (vendor + model)
        monitorDescription = mon: if mon == null then "" else "${mon.vendor or ""} ${mon.model or ""}";

        criteria = if laptopMonitor != null then monitorDescription laptopMonitor else "";
        monitor =
          if laptopMonitor != null then
            "${criteria}, ${laptopMonitor.mode}, auto, ${toString laptopMonitor.scale}"
          else
            "";
      in
      {
        systemd.user.startServices = true;

        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;
          systemd.enable = true;

          settings = lib.mkMerge [
            (lib.mkIf config.hdwlinux.theme.enable {
              misc.background_color = rgb colors.base00;
              general = {
                "col.active_border" = rgb colors.base0E;
                "col.inactive_border" = rgb colors.base03;
              };
              decoration.shadow.color = rgba colors.base00 "99";
              group = {
                "col.border_inactive" = rgb colors.base0D;
                "col.border_active" = rgb colors.base06;
                "col.border_locked_active" = rgb colors.base06;
              };
            })
            {
              workspace = [
                "special:dropdown,gapsin:5,gapsout:30,on-created-empty:appctl exec-known terminal,border:0,rounding:false,persistent:false"
              ];

              misc = {
                disable_hyprland_logo = true;
                disable_splash_rendering = true;
              };

              cursor = {
                no_hardware_cursors = true;
              };

              general = {
                gaps_in = 5;
                gaps_out = 20;
                border_size = 2;
                layout = "dwindle";
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
                gesture = [
                  "3, horizontal, workspace"
                ];
              };

              layerrule = [
                "blur,waybar"
                "ignorezero,waybar"
                "blur,notifications"
                "ignorezero,notifications"
                "blur,rofi"
                "ignorezero,rofi"
                "dimaround,rofi"
                "blur,syshud"
                "ignorezero,syshud"
              ];

              windowrule = [
                "opacity .95 .85,class:^(code)$"
                "opacity .95 .85,class:^(com.mitchellh.ghostty)$"
                "opacity .95 .85,class:^(firefox)$"
                "opacity .95 .85,class:^(jetbrains)$"
                "opacity .95 .85,class:^(org.gnome.Nautilus)$"
                "opacity .95 .85,class:^(Slack)$"
                "opacity .95 .85,class:^(spotify)$"
                "opacity .95 .85,class:^(steam)$"
                "noscreenshare,class:^(1password)$"
                "float,title:^(Quick Access — 1Password)$"
                #"dimaround,title:^(Quick Access — 1Password)$, floating"
                "center,title:^(Quick Access — 1Password)$"
                "stayfocused,title:^(Quick Access — 1Password)$"
                "workspace special:dropdown,class:^(com.mitchellh.ghostty)$"
              ];

              bind = [
                "SUPER, B, exec, appctl exec-known webBrowser"
                "SUPER, E, exec, appctl exec-known fileManager"
                "SUPER, G, togglefloating,"
                "SUPER, L, exec, appctl exec-known passwordManager toggle"
                "SUPER SHIFT, L, exec, appctl exec-known passwordManager lock"
                "SUPER, M, fullscreen, 1"
                "SUPER SHIFT, M, fullscreen, 0"
                "SUPER, O, togglesplit,"
                "SUPER, Q, killactive"
                "SUPER, S, togglegroup,"
                "SUPER, T, exec, appctl exec-known terminal"
                "SUPER SHIFT, T, movetoworkspace, special:dropdown"
                "SUPER, X, exec, appctl exec powermenu"
                "SUPER, SPACE, exec, appctl exec appctl show-menu"
                "SUPER, TAB, exec, appctl exec appctl show-windows"
                "SUPER, GRAVE, togglespecialworkspace, dropdown"
                "SUPER, V, exec, appctl exec clipboardctl show-menu"
                "SUPER, ESCAPE, exec, appctl exec missioncenter"
                "SUPER, EQUAL, exec, appctl exec woomer"
                ", PRINT, exec, appctl exec screenctl capture show-menu"
                "ALT, PRINT, exec, appctl exec screenctl record show-menu"

                "SUPER CTRL, left, workspace, -1"
                "SUPER CTRL, right, workspace, +1"
                "SUPER, left, movefocus, l"
                "SUPER, right, movefocus, r"
                "SUPER, up, movefocus, u"
                "SUPER, down, movefocus, d"
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

                "SUPER SHIFT CTRL, left, resizeactive, -100 0"
                "SUPER SHIFT CTRL, right, resizeactive, 100 0"

                ", xf86audiomute, exec, audioctl output mute toggle"
              ];

              binde = [
                ", xf86audioraisevolume, exec, audioctl output volume raise"
                ", xf86audiolowervolume, exec, audioctl output volume lower"
                ", xf86monbrightnessup, exec, screenctl backlight raise"
                ", xf86monbrightnessdown, exec, screenctl backlight lower"
              ];

              bindm = [
                "SUPER, mouse:272, movewindow"
                "SUPER, mouse:273, resizewindow"
                "SUPER, ALT_L, movewindow"
                "SUPER, Control_L, resizewindow"
              ];

              bindl = [
                ",switch:off:Lid Switch, exec, hyprctl keyword monitor \"${monitor}\""
                ",switch:on:Lid Switch, exec, hyprctl keyword monitor \"${criteria}, disable\""
              ];

            }
          ];
        };
      };
  };
}
