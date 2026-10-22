{
  config.substrate.modules.desktop.actions = {
    generic =
      { lib, ... }:
      let
        gestureType = lib.types.submodule {
          options = {
            action = lib.mkOption {
              type = lib.types.enum [
                "columnMovement"
                "workspaceSwitch"
              ];
            };
            direction = lib.mkOption {
              type = lib.types.enum [
                "horizontal"
                "vertical"
              ];
            };
            fingers = lib.mkOption {
              type = lib.types.ints.positive;
            };
          };
        };
        mouseBindingType = lib.types.submodule {
          options = {
            action = lib.mkOption {
              type = lib.types.enum [
                "focusWorkspaceDown"
                "focusWorkspaceUp"
                "moveWindow"
                "resizeWindow"
              ];
            };
            binding = lib.mkOption {
              type = lib.types.str;
            };
            description = lib.mkOption {
              type = lib.types.str;
            };
          };
        };
        actionType = lib.types.submodule {
          options = {
            binding = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional compositor-neutral key binding.";
            };
            command = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.oneOf [
                  (lib.types.listOf lib.types.str)
                  (lib.types.submodule {
                    options = {
                      type = lib.mkOption {
                        type = lib.types.enum [ "native" ];
                        description = "Native compositor command.";
                      };
                      value = lib.mkOption {
                        type = lib.types.str;
                        description = "Native compositor command value.";
                      };
                    };
                  })
                ]
              );
              default = null;
              description = "Default command, applied to any shell without an override.";
            };
            commandOverride = lib.mkOption {
              type = lib.types.attrsOf (lib.types.listOf lib.types.str);
              default = { };
              description = "Shell-specific command overrides, keyed by shell name.";
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = "Description of the action.";
            };
            showInHotkeyOverlay = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to include the action in Niri's hotkey overlay.";
            };
          };
        };
      in
      {
        options.hdwlinux.desktop.actions = lib.mkOption {
          type = lib.types.attrsOf actionType;
          default = { };
          description = "Semantic desktop actions and their optional key bindings.";
        };
        options.hdwlinux.desktop.gestures = lib.mkOption {
          type = lib.types.listOf gestureType;
          default = [ ];
        };
        options.hdwlinux.desktop.mouseBindings = lib.mkOption {
          type = lib.types.attrsOf mouseBindingType;
          default = { };
        };
      };

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        apps = config.hdwlinux.desktop.apps;
        appAction = name: description: binding: {
          inherit binding description;
          command = [ "app-${name}" ];
        };
        actions = config.hdwlinux.desktop.actions;
        # Actions carrying shell overrides are resolved at runtime by the
        # hdwlinux-action dispatcher, which reads $HDWLINUX_SHELL to select the
        # commandOverride entry (falling back to the action's default command).
        dispatchable = lib.filterAttrs (_: action: action.commandOverride != { }) actions;
        hdwlinux-action = pkgs.writeShellScriptBin "hdwlinux-action" (
          ''
            set -eu
            action="''${1:?usage: hdwlinux-action <action>}"
            shell="''${HDWLINUX_SHELL:-}"
            case "$action" in
          ''
          + lib.concatStrings (
            lib.mapAttrsToList (
              name: action:
              let
                overrides = lib.concatStrings (
                  lib.mapAttrsToList (shell: cmd: ''
                    ${shell}) exec ${lib.escapeShellArgs cmd} ;;
                  '') action.commandOverride
                );
                fallback =
                  if builtins.isList action.command then
                    "exec ${lib.escapeShellArgs action.command}"
                  else
                    ''
                      echo "hdwlinux-action: no command for '${name}' under shell '$shell'" >&2
                      exit 1
                    '';
              in
              ''
                ${name})
                  case "$shell" in
                  ${overrides}
                  *) ${fallback} ;;
                  esac
                  ;;
              ''
            ) dispatchable
          )
          + ''
            *)
              echo "hdwlinux-action: unknown action '$action'" >&2
              exit 1
              ;;
            esac
          ''
        );
      in
      {
        home.packages = [ hdwlinux-action ];
        hdwlinux.desktop.gestures = [
          {
            action = "workspaceSwitch";
            direction = "vertical";
            fingers = 3;
          }
          {
            action = "columnMovement";
            direction = "horizontal";
            fingers = 3;
          }
        ];
        hdwlinux.desktop.mouseBindings = {
          focusWorkspaceDown = {
            action = "focusWorkspaceDown";
            binding = "Mod+mouse_down";
            description = "Focus the next workspace with the mouse wheel";
          };
          focusWorkspaceUp = {
            action = "focusWorkspaceUp";
            binding = "Mod+mouse_up";
            description = "Focus the previous workspace with the mouse wheel";
          };
          moveWindow = {
            action = "moveWindow";
            binding = "Mod+mouse:272";
            description = "Move the focused window with the mouse";
          };
          resizeWindow = {
            action = "resizeWindow";
            binding = "Mod+mouse:273";
            description = "Resize the focused window with the mouse";
          };
        };
        hdwlinux.desktop.actions = lib.mkMerge [
          (lib.optionalAttrs (apps.terminal != null) {
            launchTerminal = (appAction "terminal" "Launch terminal" "Mod+T") // {
              showInHotkeyOverlay = true;
            };
          })
          (lib.optionalAttrs (apps.webBrowser != null) {
            launchWebBrowser = (appAction "webBrowser" "Launch web browser" "Mod+B") // {
              showInHotkeyOverlay = true;
            };
          })
          (lib.optionalAttrs (apps.fileManager != null) {
            launchFileManager = (appAction "fileManager" "Launch file manager" "Mod+E") // {
              showInHotkeyOverlay = true;
            };
          })
          (lib.optionalAttrs (apps.passwordManager-toggle != null) {
            togglePasswordManager = (appAction "passwordManager-toggle" "Toggle password manager" "Mod+L") // {
              showInHotkeyOverlay = true;
            };
          })
          (lib.optionalAttrs (apps.passwordManager-lock != null) {
            lockPasswordManager = (appAction "passwordManager-lock" "Lock password manager" "Mod+Shift+L") // {
              showInHotkeyOverlay = true;
            };
          })
          {
            centerColumn = {
              binding = "Mod+Return";
              description = "Center the focused column";
            };
            closeWindow = {
              binding = "Mod+Q";
              description = "Close the focused window";
              showInHotkeyOverlay = true;
            };
            exitCompositor = {
              binding = "Mod+Ctrl+Shift+E";
              description = "Exit the compositor";
              showInHotkeyOverlay = true;
            };
            consumeWindowLeft = {
              binding = "Mod+Shift+BracketLeft";
              description = "Consume the window to the left";
            };
            consumeWindowRight = {
              binding = "Mod+Shift+BracketRight";
              description = "Consume the window to the right";
            };
            focusWindowDown = {
              binding = "Mod+Down";
              description = "Focus the window below";
              showInHotkeyOverlay = true;
            };
            focusWindowLeft = {
              binding = "Mod+Left";
              description = "Focus the window to the left";
              showInHotkeyOverlay = true;
            };
            focusWindowRight = {
              binding = "Mod+Right";
              description = "Focus the window to the right";
              showInHotkeyOverlay = true;
            };
            focusWindowUp = {
              binding = "Mod+Up";
              description = "Focus the window above";
              showInHotkeyOverlay = true;
            };
            focusWorkspaceDown = {
              binding = "Mod+Page_Down";
              description = "Focus the workspace below";
            };
            focusWorkspaceUp = {
              binding = "Mod+Page_Up";
              description = "Focus the workspace above";
            };
            increaseColumnWidth = {
              binding = "Mod+Equal";
              description = "Increase the column width";
            };
            increaseWindowHeight = {
              binding = "Mod+Shift+Equal";
              description = "Increase the window height";
            };
            maximizeWindow = {
              binding = "Mod+Shift+Return";
              description = "Maximize the focused window";
            };
            moveColumnDown = {
              binding = "Mod+Shift+Down";
              description = "Move the column down";
            };
            moveColumnLeft = {
              binding = "Mod+Shift+Left";
              description = "Move the column left";
            };
            moveColumnRight = {
              binding = "Mod+Shift+Right";
              description = "Move the column right";
            };
            moveColumnUp = {
              binding = "Mod+Shift+Up";
              description = "Move the column up";
            };
            moveWorkspaceDown = {
              binding = "Mod+Shift+Page_Down";
              description = "Move the workspace down";
            };
            moveWorkspaceUp = {
              binding = "Mod+Shift+Page_Up";
              description = "Move the workspace up";
            };
            switchColumnWidth = {
              binding = "Mod+R";
              description = "Switch the column width preset";
            };
            toggleScratchpad = {
              binding = "Mod+Grave";
              description = "Toggle the scratchpad";
              showInHotkeyOverlay = true;
            };
            toggleFloating = {
              binding = "Mod+Shift+F";
              description = "Toggle floating mode";
              showInHotkeyOverlay = true;
            };
            toggleFullscreen = {
              binding = "Mod+F";
              description = "Toggle fullscreen";
              showInHotkeyOverlay = true;
            };
            toggleOverview = {
              binding = "Mod+Tab";
              description = "Toggle the overview";
              showInHotkeyOverlay = true;
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "window-switcher"
                ];
                custom = [
                  "vicinae"
                  "vicinae://launch/windows?toggle=true"
                ];
                dux = [ "dms-overview" ];
              };
            };
            toggleTabbedDisplay = {
              binding = "Mod+W";
              description = "Toggle tabbed display";
              showInHotkeyOverlay = true;
            };
            takeScreenScreenshot = {
              binding = "Ctrl+Print";
              description = "Take a screenshot of the screen";
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "screenshot-fullscreen"
                ];
                custom = [
                  "screenctl"
                  "capture"
                  "desktop"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "quickCapture"
                  "screenshot"
                  "full"
                  "edit"
                ];
              };
            };
            takeWindowScreenshot = {
              binding = "Alt+Print";
              description = "Take a screenshot of the window";
              commandOverride = {
                # Noctalia has no window capture; picking the region is the
                # closest thing it offers.
                noctalia = [
                  "noctalia"
                  "msg"
                  "screenshot-region"
                ];
                custom = [
                  "screenctl"
                  "capture"
                  "window"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "quickCapture"
                  "screenshot"
                  "window"
                  "edit"
                ];
              };
            };
            showHotkeyOverlay = {
              binding = "Mod+Shift+Slash";
              description = "Show the hotkey overlay";
              showInHotkeyOverlay = false;
            };
          }
          {
            showApplicationLauncher = {
              binding = "Mod+Space";
              description = "Show application launcher";
              showInHotkeyOverlay = true;
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "panel-toggle"
                  "launcher"
                ];
                custom = [
                  "vicinae"
                  "vicinae://toggle"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "spotlight"
                  "toggle"
                ];
              };
            };
            showClipboard = {
              binding = "Mod+V";
              description = "Show clipboard menu";
              showInHotkeyOverlay = true;
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "panel-toggle"
                  "clipboard"
                ];
                custom = [
                  "clipboardctl"
                  "show-menu"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "clipboard"
                  "toggle"
                ];
              };
            };
            showControlCenter = {
              binding = "Mod+S";
              description = "Show control center";
              showInHotkeyOverlay = true;
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "panel-toggle"
                  "control-center"
                ];
                custom = [
                  "controlctl"
                  "show-menu"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "control-center"
                  "toggle"
                ];
              };
            };
            showPowerMenu = {
              binding = "Mod+X";
              description = "Show power menu";
              showInHotkeyOverlay = true;
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "panel-toggle"
                  "session"
                ];
                custom = [
                  "vicinae"
                  "vicinae://launch/power?toggle=true"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "powermenu"
                  "toggle"
                ];
              };
            };
            showScreenRecordMenu = {
              binding = "Print";
              description = "Toggle screen recording";
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "plugin"
                  "noctalia/screen_recorder:service"
                  "all"
                  "toggle"
                ];
                custom = [
                  "screenctl"
                  "record"
                  "show-menu"
                ];
                # DMS has no built-in recorder; the QuickCapture plugin is the
                # shell's capture surface and exposes its menu over IPC.
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "quickCapture"
                  "open"
                ];
              };
            };
            showShellSettings = {
              binding = "Mod+Comma";
              description = "Show shell settings";
              showInHotkeyOverlay = true;
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "settings-toggle"
                ];
                custom = [
                  "vicinae"
                  "vicinae://settings/open"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "settings"
                  "focusOrToggle"
                ];
              };
            };
            toggleAudioMute = {
              binding = "XF86AudioMute";
              description = "Toggle audio mute";
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "volume-mute"
                ];
                custom = [
                  "audioctl"
                  "output"
                  "mute"
                  "toggle"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "audio"
                  "mute"
                ];
              };
            };
            volumeLower = {
              binding = "XF86AudioLowerVolume";
              description = "Lower volume";
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "volume-down"
                ];
                custom = [
                  "audioctl"
                  "output"
                  "volume"
                  "lower"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "audio"
                  "decrement"
                  "3"
                ];
              };
            };
            volumeRaise = {
              binding = "XF86AudioRaiseVolume";
              description = "Raise volume";
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "volume-up"
                ];
                custom = [
                  "audioctl"
                  "output"
                  "volume"
                  "raise"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "audio"
                  "increment"
                  "3"
                ];
              };
            };
            brightnessLower = {
              binding = "XF86MonBrightnessDown";
              description = "Lower brightness";
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "brightness-down"
                ];
                custom = [
                  "screenctl"
                  "backlight"
                  "lower"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "brightness"
                  "decrement"
                  "5"
                  ""
                ];
              };
            };
            brightnessRaise = {
              binding = "XF86MonBrightnessUp";
              description = "Raise brightness";
              commandOverride = {
                noctalia = [
                  "noctalia"
                  "msg"
                  "brightness-up"
                ];
                custom = [
                  "screenctl"
                  "backlight"
                  "raise"
                ];
                dux = [
                  "dms"
                  "ipc"
                  "call"
                  "brightness"
                  "increment"
                  "5"
                  ""
                ];
              };
            };
          }
          (lib.genAttrs (map (number: "focusWorkspace${toString number}") (lib.range 1 10)) (
            name:
            let
              number = lib.removePrefix "focusWorkspace" name;
            in
            {
              binding = "Mod+${if number == "10" then "0" else number}";
              description = "Focus workspace ${number}";
            }
          ))
          (lib.genAttrs (map (number: "moveColumnToWorkspace${toString number}") (lib.range 1 10)) (
            name:
            let
              number = lib.removePrefix "moveColumnToWorkspace" name;
            in
            {
              binding = "Mod+Shift+${if number == "10" then "0" else number}";
              description = "Move the column to workspace ${number}";
            }
          ))
        ];
      };
  };
}
