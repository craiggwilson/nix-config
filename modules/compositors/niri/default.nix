{
  config.substrate.modules.compositors.niri = {
    tags = [
      "compositor:niri"
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

        hdwlinux.compositors.sessions.niri = {
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
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
          ];
          xdgOpenUsePortal = true;
        };
      };

    homeManager =
      {
        inputs,
        config,
        hasTag,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
        flake = config.hdwlinux.flake;
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
          takeScreenshot = "screenshot";
          takeScreenScreenshot = "screenshot-screen";
          takeWindowScreenshot = "screenshot-window";
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
        actionBinding =
          action:
          if builtins.isList action.command then
            "{ spawn ${lib.concatMapStringsSep " " builtins.toJSON action.command}; }"
          else
            "{ ${action.command.value}; }";
        actionBindings =
          lib.concatMapStringsSep "\n"
            (
              name:
              let
                action = config.hdwlinux.desktop.actions.${name};
                command =
                  if nativeActions ? ${name} then
                    {
                      type = "native";
                      value = nativeActions.${name};
                    }
                  else
                    action.command;
              in
              "    ${action.binding} hotkey-overlay-title=${
                    if action.showInHotkeyOverlay then builtins.toJSON action.description else "null"
                  } ${actionBinding (action // { inherit command; })}"
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
            include "shell.kdl"
            include "actions.kdl"
          '';

          "niri/common.kdl".source = ./config/common.kdl;

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
        }
        // lib.optionalAttrs (flake != null) {
          "niri/shell.kdl".source = config.lib.file.mkOutOfStoreSymlink (
            if hasTag "desktop:noctalia" then
              "${flake}/modules/compositors/niri/config/noctalia.kdl"
            else
              "${flake}/modules/compositors/niri/config/custom.kdl"
          );
        };
      };
  };
}
