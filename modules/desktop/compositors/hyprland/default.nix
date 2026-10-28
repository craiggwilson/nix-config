let
  # Shared configuration values for both NixOS and home-manager
  xwaylandEnabled = true;
in
{
  config.substrate.modules.desktop.compositors.hyprland = {
    tags = [ "desktop:compositors:hyprland" ];

    nixos =
      _:
      {
        programs.hyprland = {
          enable = true;
          xwayland.enable = xwaylandEnabled;
        };

        hdwlinux.desktop.compositors.hyprland = {
          command = "/run/current-system/sw/bin/start-hyprland";
          comment = "A dynamic tiling Wayland compositor";
          desktopName = "Hyprland";
          prettyName = "Hyprland";
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
        actionBindings = lib.concatStringsSep "" (
          lib.mapAttrsToList (
            name: action:
            let
              parts = lib.splitString "+" action.binding;
              key = lib.last parts;
              modifiers = lib.init parts;
              hyprModifiers = lib.concatStringsSep " + " (
                map (
                  modifier:
                  lib.replaceStrings [ "Mod" "Shift" "Ctrl" "Alt" ] [ "SUPER" "SHIFT" "CTRL" "ALT" ] modifier
                ) modifiers
              );
              command =
                # Resolution order: native compositor mapping, then the
                # hdwlinux-action dispatcher (when shell overrides exist), then
                # the default command.
                nativeActions.${name} or (
                  if action.commandOverride != { } then
                    "hl.dsp.exec_cmd(${builtins.toJSON "hdwlinux-action ${name}"})"
                  else if action.command != null then
                    (
                      if builtins.isList action.command then
                        "hl.dsp.exec_cmd(${builtins.toJSON (lib.concatStringsSep " " action.command)})"
                      else
                        "hl.dsp.exec_cmd(${builtins.toJSON action.command.value})"
                    )
                  else
                    throw "hyprland: action '${name}' has no native mapping, command, or commandOverride"
                );
            in
            ''
              hl.bind(${
                builtins.toJSON (if modifiers == [ ] then key else "${hyprModifiers} + ${key}")
              }, ${command})
            ''
          ) (lib.filterAttrs (_: action: action.binding != null) config.hdwlinux.desktop.actions)
        );
        nativeActionCommands = {
          centerColumn = "hl.dsp.window.center()";
          closeWindow = "hl.dsp.window.close()";
          exitCompositor = "hl.dsp.exit()";
          consumeWindowLeft = ''hl.dsp.layout("consume_or_expel prev")'';
          consumeWindowRight = ''hl.dsp.layout("consume_or_expel next")'';
          focusWindowDown = ''hl.dsp.focus({ direction = "down" })'';
          focusWindowLeft = ''hl.dsp.layout("focus l")'';
          focusWindowRight = ''hl.dsp.layout("focus r")'';
          focusWindowUp = ''hl.dsp.focus({ direction = "up" })'';
          focusWorkspaceDown = ''hl.dsp.focus({ workspace = "e-1" })'';
          focusWorkspaceUp = ''hl.dsp.focus({ workspace = "e+1" })'';
          increaseColumnWidth = ''hl.dsp.layout("colresize +0.1")'';
          increaseWindowHeight = "hl.dsp.window.resize()";
          maximizeWindow = "hl.dsp.window.fullscreen({ mode = 1 })";
          moveColumnDown = ''hl.dsp.window.move({ direction = "down" })'';
          moveColumnLeft = ''hl.dsp.layout("swapcol l")'';
          moveColumnRight = ''hl.dsp.layout("swapcol r")'';
          moveColumnUp = ''hl.dsp.window.move({ direction = "up" })'';
          moveWorkspaceDown = ''hl.dsp.window.move({ workspace = "e-1" })'';
          moveWorkspaceUp = ''hl.dsp.window.move({ workspace = "e+1" })'';
          switchColumnWidth = ''hl.dsp.layout("colresize +conf")'';
          showHotkeyOverlay = ''hl.dsp.exec_cmd("uwsm app -- vicinae vicinae://launch/keybind-cheatsheet")'';
          toggleFloating = ''hl.dsp.window.float({ action = "toggle" })'';
          toggleFullscreen = "hl.dsp.window.fullscreen({ mode = 1 })";
          toggleScratchpad = ''hl.dsp.workspace.toggle_special("dropdown")'';
          toggleTabbedDisplay = "hl.dsp.group.toggle()";
        };
        nativeActions =
          nativeActionCommands
          // lib.concatMapAttrs (number: _: {
            "focusWorkspace${number}" = "hl.dsp.focus({ workspace = ${number} })";
            "moveColumnToWorkspace${number}" = "hl.dsp.window.move({ workspace = ${number} })";
          }) (lib.genAttrs (map toString (lib.range 1 10)) (_: { }));
        mouseBindingCommands = {
          focusWorkspaceDown = ''hl.dsp.focus({ workspace = "e+1" })'';
          focusWorkspaceUp = ''hl.dsp.focus({ workspace = "e-1" })'';
          moveWindow = "hl.dsp.window.drag()";
          resizeWindow = "hl.dsp.window.resize()";
        };
        mouseBindings = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            _: binding:
            let
              parts = lib.splitString "+" binding.binding;
              key = lib.last parts;
              modifiers = lib.init parts;
              modifierText = lib.concatStringsSep " + " (
                map (
                  modifier:
                  lib.replaceStrings [ "Mod" "Shift" "Ctrl" "Alt" ] [ "SUPER" "SHIFT" "CTRL" "ALT" ] modifier
                ) modifiers
              );
            in
            "hl.bind(${builtins.toJSON (if modifiers == [ ] then key else "${modifierText} + ${key}")}, ${
              mouseBindingCommands.${binding.action}
            }, { mouse = true })"
          ) config.hdwlinux.desktop.mouseBindings
        );
        gestures = lib.concatStringsSep "\n" (
          map (
            gesture:
            ''hl.gesture({ fingers = ${toString gesture.fingers}, direction = "${gesture.direction}", action = "workspace" })''
          ) (lib.filter (gesture: gesture.action == "workspaceSwitch") config.hdwlinux.desktop.gestures)
        );
        columnGesture = lib.findFirst (
          gesture: gesture.action == "columnMovement"
        ) null config.hdwlinux.desktop.gestures;
        colors = config.hdwlinux.theme.colors.hex;
        rgb = color: "rgb(${color})";
        rgba = color: alpha: "rgba(${color}${alpha})";

        # Helper to describe monitor (vendor + model)
      in
      {
        systemd.user.startServices = true;

        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;
          systemd.enable = false;
          configType = "lua";

          settings = {
            config = {
              misc = {
                background_color = rgb colors.base00;
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
                layout = "scrolling";
                "col.active_border" = rgb colors.base0E;
                "col.inactive_border" = rgb colors.base03;
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
                  color = rgba colors.base00 "99";
                  range = 4;
                  render_power = 3;
                };

                dim_special = 0.2;
              };

              group = {
                "col.border_inactive" = rgb colors.base0D;
                "col.border_active" = rgb colors.base06;
                "col.border_locked_active" = rgb colors.base06;
              };

              animations = {
                enabled = true;
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

              scrolling = {
                column_width = 0.9;
                fullscreen_on_one_column = false;
                follow_focus = true;
                focus_fit_method = 1;
                direction = "right";
              };

            };
          };

          extraConfig = ''
            hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
            hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
            hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
            hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
            hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
            hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
            hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "slidevert" })
            hl.workspace_rule({ workspace = "special:dropdown", gaps_in = 5, gaps_out = 30, on_created_empty = "app-terminal", border_size = 0, no_rounding = true, persistent = false })
            ${mouseBindings}
            ${gestures}
            local horizontalGestureDirection = 0
            ${lib.optionalString (columnGesture != null) ''
              hl.gesture({
                fingers = ${toString columnGesture.fingers},
                direction = "${columnGesture.direction}",
                action = {
                  start = function() horizontalGestureDirection = 0 end,
                  update = function(e) horizontalGestureDirection = e.delta.x end,
                  finish = function()
                    if horizontalGestureDirection ~= 0 then
                      hl.dispatch(hl.dsp.layout(horizontalGestureDirection > 0 and "focus l" or "focus r"))
                    end
                  end,
                },
              })
            ''}
            ${actionBindings}
            hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("uwsm app -- missioncenter"))
            hl.bind("SUPER + EQUAL", hl.dsp.exec_cmd("uwsm app -- woomer"))
            local opacity_rules = {
              { name = "code-opacity", match = { class = "^(code)$" }, opacity = "0.95 0.85" },
              { name = "ghostty-opacity", match = { class = "^(com.mitchellh.ghostty)$" }, opacity = "0.95 0.85" },
              { name = "firefox-opacity", match = { class = "^(firefox)$" }, opacity = "0.95 0.85" },
              { name = "jetbrains-opacity", match = { class = "^(jetbrains)$" }, opacity = "0.95 0.85" },
              { name = "nautilus-opacity", match = { class = "^(org.gnome.Nautilus)$" }, opacity = "0.95 0.85" },
              { name = "slack-opacity", match = { class = "^(Slack)$" }, opacity = "0.95 0.85" },
              { name = "spotify-opacity", match = { class = "^(spotify)$" }, opacity = "0.95 0.85" },
              { name = "steam-opacity", match = { class = "^(steam)$" }, opacity = "0.95 0.85" },
            }
            for _, rule in ipairs(opacity_rules) do hl.window_rule(rule) end
            hl.window_rule({ name = "password-manager", match = { class = "^(1password)$" }, no_screen_share = true })
            hl.window_rule({ name = "password-manager-quick-access", match = { title = "^Quick Access — 1Password$" }, float = true, center = true, stay_focused = true })
            hl.window_rule({ name = "scratch-terminal", match = { class = "^(com.mitchellh.ghostty)$" }, workspace = "special:dropdown" })
            hl.layer_rule({ name = "waybar-blur", match = { namespace = "^waybar$" }, blur = true, ignore_alpha = true })
            hl.layer_rule({ name = "notifications-blur", match = { namespace = "^notifications$" }, blur = true, ignore_alpha = true })
            hl.layer_rule({ name = "vicinae-blur", match = { namespace = "^vicinae$" }, blur = true, ignore_alpha = true, dim_around = true })
             hl.layer_rule({ name = "syshud-blur", match = { namespace = "^syshud$" }, blur = true, ignore_alpha = true })
             for _, namespace in ipairs({
               "bar", "dock", "osd", "toast", "tooltip", "tray-menu-window",
               "workspace-overview", "control-center", "app-launcher", "dash",
               "notification-center-popout", "popout", "clipboard", "settings",
               "spotlight", "polkit", "power-menu", "process-list-modal",
               "file-browser", "color-picker", "network-info", "modal",
             }) do
               hl.layer_rule({ name = "dms-" .. namespace .. "-blur", match = { namespace = "^dms:" .. namespace .. "$" }, blur = true, ignore_alpha = true })
             end
          '';
        };
      };
  };
}
