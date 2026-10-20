let
  # Shared configuration values for both NixOS and home-manager
  xwaylandEnabled = true;
in
{
  config.substrate.modules.compositors.hyprland = {
    tags = [
      "compositor:hyprland"
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
        ...
      }:
      let
        actionBindings = lib.mapAttrsToList (
          _: action:
          let
            parts = lib.splitString "+" action.binding;
            key = lib.last parts;
            modifiers = lib.init parts;
            hyprModifiers = lib.concatStringsSep " " (
              map (
                modifier:
                lib.replaceStrings [ "Mod" "Shift" "Ctrl" "Alt" ] [ "SUPER" "SHIFT" "CTRL" "ALT" ] modifier
              ) modifiers
            );
            command =
              if builtins.isList action.command then
                "exec, ${lib.concatStringsSep " " action.command}"
              else
                action.command.value;
          in
          "${hyprModifiers}, ${key}, ${command}"
        ) (lib.filterAttrs (_: action: action.binding != null) config.hdwlinux.desktop.actions);
        nativeActionCommands = {
          centerColumn = "centerwindow";
          closeWindow = "killactive";
          exitCompositor = "exit";
          consumeWindowLeft = "movewindow l";
          consumeWindowRight = "movewindow r";
          focusWindowDown = "movefocus d";
          focusWindowLeft = "movefocus l";
          focusWindowRight = "movefocus r";
          focusWindowUp = "movefocus u";
          focusWorkspaceDown = "workspace -1";
          focusWorkspaceUp = "workspace +1";
          increaseColumnWidth = "resizeactive 100 0";
          increaseWindowHeight = "resizeactive 0 100";
          maximizeWindow = "fullscreen 1";
          moveColumnDown = "movewindow d";
          moveColumnLeft = "movewindow l";
          moveColumnRight = "movewindow r";
          moveColumnUp = "movewindow u";
          moveWorkspaceDown = "movetoworkspace -1";
          moveWorkspaceUp = "movetoworkspace +1";
          switchColumnWidth = "alterzorder top";
          showHotkeyOverlay = "exec, uwsm app -- vicinae vicinae://launch/keybind-cheatsheet";
          takeScreenshot = "exec, uwsm app -- screenctl capture show-menu";
          takeScreenScreenshot = "exec, uwsm app -- screenctl capture show-menu";
          takeWindowScreenshot = "exec, uwsm app -- screenctl capture show-menu";
          toggleFloating = "togglefloating";
          toggleFullscreen = "fullscreen 1";
          toggleOverview = "overview, toggle";
          toggleScratchpad = "togglespecialworkspace, dropdown";
          toggleTabbedDisplay = "togglegroup";
        };
        nativeActions =
          nativeActionCommands
          // lib.concatMapAttrs (number: _: {
            "focusWorkspace${number}" = "workspace ${number}";
            "moveColumnToWorkspace${number}" = "movetoworkspace ${number}";
          }) (lib.genAttrs (map toString (lib.range 1 10)) (_: { }));
        colors = config.hdwlinux.theme.colors.hex;
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
        hdwlinux.desktop.actions = lib.mapAttrs (_: value: {
          command = {
            type = "native";
            inherit value;
          };
        }) nativeActions;

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
                "special:dropdown,gapsin:5,gapsout:30,on-created-empty:app-terminal,border:0,rounding:false,persistent:false"
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
                "blur,vicinae"
                "ignorezero,vicinae"
                "dimaround,vicinae"
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

              bind = actionBindings ++ [
                "SUPER, ESCAPE, exec, uwsm app -- missioncenter"
                "SUPER, EQUAL, exec, uwsm app -- woomer"

              ];

              binde = [ ];

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
