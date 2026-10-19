{
  config.substrate.modules.desktop.actions = {
    generic =
      { lib, ... }:
      let
        actionType = lib.types.submodule {
          options = {
            binding = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional compositor-neutral key binding.";
            };
            command = lib.mkOption {
              type = lib.types.oneOf [
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
              ];
              description = "Command implementation for this action.";
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
      };

    homeManager =
      { config, lib, ... }:
      let
        apps = config.hdwlinux.desktop.apps;
        appAction = name: description: binding: {
          inherit binding description;
          command = [ "app-${name}" ];
        };
      in
      {
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
            };
            toggleTabbedDisplay = {
              binding = "Mod+W";
              description = "Toggle tabbed display";
              showInHotkeyOverlay = true;
            };
            takeScreenshot = {
              binding = "Print";
              description = "Take a screenshot";
            };
            takeScreenScreenshot = {
              binding = "Ctrl+Print";
              description = "Take a screenshot of the screen";
            };
            takeWindowScreenshot = {
              binding = "Alt+Print";
              description = "Take a screenshot of the window";
            };
            showHotkeyOverlay = {
              binding = "Mod+Shift+Slash";
              description = "Show the hotkey overlay";
              showInHotkeyOverlay = false;
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
