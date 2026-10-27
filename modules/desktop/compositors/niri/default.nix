{
  config.substrate.modules.desktop.compositors.niri = {
    tags = [
      "desktop:compositors:niri"
    ];

    nixos =
      {
        lib,
        pkgs,
        ...
      }:
      {
        programs = {
          niri.enable = true;
        };

        hdwlinux.desktop.compositors.niri = {
          command = "/run/current-system/sw/bin/niri-session";
          comment = "A scrollable-tiling Wayland compositor";
          desktopName = "niri";
          prettyName = "Niri";
        };

        services = {
          xserver.desktopManager.runXdgAutostartIfNone = true;
        };

        systemd.packages = [ pkgs.niri ];

        environment.sessionVariables = {
          GSK_RENDERER = "gl";
        };

        xdg.portal = {
          enable = true;
          configPackages = [ pkgs.niri ];
          config.niri = {
            default = lib.mkForce [
              "gnome"
              "gtk"
            ];
            # Route screen sharing to gnome portal for window selection support
            "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
            "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
          xdgOpenUsePortal = true;
        };
      };

    homeManager =
      {
        inputs,
        config,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
        nativeActionCommands = {
          centerColumn = "center-column";
          closeWindow = "close-window";
          consumeWindowLeft = "consume-or-expel-window-left";
          consumeWindowRight = "consume-or-expel-window-right";
          exitCompositor = "quit";
          focusWindowDown = "focus-window-or-monitor-down";
          focusWindowLeft = "focus-column-or-monitor-left";
          focusWindowRight = "focus-column-or-monitor-right";
          focusWindowUp = "focus-window-or-monitor-up";
          focusWorkspaceDown = "focus-workspace-down";
          focusWorkspaceUp = "focus-workspace-up";
          increaseColumnWidth = ''set-column-width "+10%"'';
          increaseWindowHeight = ''set-window-height "+10%"'';
          maximizeWindow = "maximize-window-to-edges";
          moveColumnDown = "move-window-down";
          moveColumnLeft = "move-column-left-or-to-monitor-left";
          moveColumnRight = "move-column-right-or-to-monitor-right";
          moveColumnUp = "move-window-up";
          moveWorkspaceDown = "move-workspace-down";
          moveWorkspaceUp = "move-workspace-up";
          switchColumnWidth = "switch-preset-column-width";
          showHotkeyOverlay = "show-hotkey-overlay";
          toggleFloating = "toggle-window-floating";
          toggleFullscreen = "fullscreen-window";
          toggleOverview = "toggle-overview";
          toggleScratchpad = ''spawn "niri-scratchpad" "target" "--spawn" "app-terminal --class=scratch.terminal" "appid" "scratch.terminal"'';
          toggleTabbedDisplay = "toggle-column-tabbed-display";
        };
        nativeActions =
          nativeActionCommands
          // lib.concatMapAttrs (number: _: {
            "focusWorkspace${number}" = "focus-workspace ${number}";
            "moveColumnToWorkspace${number}" = "move-column-to-workspace ${number}";
          }) (lib.genAttrs (map toString (lib.range 1 10)) (_: { }));
        # Resolution order: native compositor mapping, then the hdwlinux-action
        # dispatcher (when shell overrides exist), then the default command.
        resolveCommand =
          name: action:
          if nativeActions ? ${name} then
            {
              type = "native";
              value = nativeActions.${name};
            }
          else if action.commandOverride != { } then
            {
              type = "spawn";
              argv = [
                "hdwlinux-action"
                name
              ];
            }
          else if action.command != null then
            (
              if builtins.isList action.command then
                {
                  type = "spawn";
                  argv = action.command;
                }
              else
                {
                  type = "native";
                  value = action.command.value;
                }
            )
          else
            throw "niri: action '${name}' has no native mapping, command, or commandOverride";
        renderSpec =
          spec:
          if spec.type == "native" then
            "{ ${spec.value}; }"
          else
            "{ spawn ${lib.concatMapStringsSep " " builtins.toJSON spec.argv}; }";
        actionBindings =
          lib.concatMapStringsSep "\n"
            (
              name:
              let
                action = config.hdwlinux.desktop.actions.${name};
              in
              "    ${action.binding} hotkey-overlay-title=${
                    if action.showInHotkeyOverlay then builtins.toJSON action.description else "null"
                  } ${renderSpec (resolveCommand name action)}"
            )
            (
              lib.filter (name: config.hdwlinux.desktop.actions.${name}.binding != null) (
                builtins.attrNames config.hdwlinux.desktop.actions
              )
            );
        mouseBindings = lib.concatMapStringsSep "\n" (
          binding:
          let
            niriBinding =
              lib.replaceStrings [ "Mod+mouse_down" "Mod+mouse_up" ] [ "Mod+WheelScrollDown" "Mod+WheelScrollUp" ]
                binding.binding;
            action = lib.attrByPath [ binding.action ] null {
              focusWorkspaceDown = "focus-workspace-down";
              focusWorkspaceUp = "focus-workspace-up";
            };
          in
          lib.optionalString (action != null) "    ${niriBinding} { ${action}; }"
        ) (lib.attrValues config.hdwlinux.desktop.mouseBindings);
      in
      {
        home.packages = [
          (pkgs.xwayland-satellite.override { withSystemd = false; })
          inputs.niri-scratchpad.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        home.sessionVariables.NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";

        systemd.user.startServices = true;

        xdg.configFile = {
          "niri/config.kdl".text = ''
            include "colors.kdl"
            include "common.kdl"
            include "noctalia.kdl"
            include "custom.kdl"
            include "dux.kdl"
            include "actions.kdl"
          '';

          "niri/common.kdl".source = ./config/common.kdl;
          "niri/noctalia.kdl".source = ./config/noctalia.kdl;
          "niri/custom.kdl".source = ./config/custom.kdl;
          "niri/dux.kdl".source = ./config/dux.kdl;

          "niri/colors.kdl".text = ''
            layout {
                background-color "${colors.base00}"

                focus-ring {
                    active-color "${colors.base0E}"
                    inactive-color "${colors.base03}"
                    urgent-color "${colors.base06}"
                }

                insert-hint {
                    color "${colors.base09}80"
                }

                tab-indicator {
                    active-color "${colors.base0B}"
                    inactive-color "${colors.base03}"
                    urgent-color "${colors.base06}"
                }
            }

            overview {
                backdrop-color "${colors.base00}"
            }

            window-rule {
                match is-window-cast-target=true
                focus-ring {
                    active-color "${colors.base0A}80"
                }
                shadow {
                    on
                    color "${colors.base0A}80"
                }
            }

            window-rule {
                match is-floating=true

                shadow {
                    on
                    
                    softness 40
                    draw-behind-window true
                    spread 25
                    color "#7d0d2d70"
                }

                focus-ring {
                    active-color "${colors.base08}"
                }
            }
          '';

          "niri/actions.kdl".text = ''
              binds {
            ${actionBindings}
            ${mouseBindings}
              }
          '';
        };
      };
  };
}
